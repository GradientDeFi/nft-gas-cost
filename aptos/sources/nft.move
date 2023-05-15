module nft_mint_cost::create_and_mint_nft {
    use std::debug;
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::aptos_account;
    use aptos_framework::aptos_coin;
    use aptos_framework::coin;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::resource_account;
    use aptos_framework::timestamp;
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    use aptos_token::token::{Self, TokenDataId};

    // This struct stores the token receiver's address and token_data_id in the event of token minting
    struct TokenMintingEvent has drop, store {
        token_receiver_address: address,
        token_data_id: TokenDataId,
    }

    // This struct stores an NFT collection's relevant information
    struct ModuleData has key {
        signer_cap: account::SignerCapability,
        token_data_id: TokenDataId,
        expiration_timestamp: u64,
        minting_enabled: bool,
        token_minting_events: EventHandle<TokenMintingEvent>,
    }

    /// Action not authorized because the signer is not the admin of this module
    const ENOT_AUTHORIZED: u64 = 1;
    /// The collection minting is expired
    const ECOLLECTION_EXPIRED: u64 = 2;
    /// The collection minting is disabled
    const EMINTING_DISABLED: u64 = 3;

    fun init_module(resource_signer: &signer) {
        let collection_name = string::utf8(b"GraDeFi");
        let description = string::utf8(b"GraDeFi NFT Mint Gas Cost");
        let collection_uri = string::utf8(b"https://gradefi.com");
        let token_name = string::utf8(b"Aptos NFT Mint");
        let token_uri = string::utf8(b"https://gradefi.com/nftcost");
        // This means that the supply of the token will be tracked.
        let maximum_supply = 1_000_000;
        // This variable sets if we want to allow mutation for collection description, uri, and maximum.
        // Here, we are setting all of them to false, which means that we don't allow mutations to any CollectionData fields.
        let mutate_setting = vector<bool>[ false, false, false ];

        // Create the nft collection.
        token::create_collection(resource_signer, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        // Create a token data id to specify the token to be minted.
        let token_data_id = token::create_tokendata(
            resource_signer,
            collection_name,
            token_name,
            string::utf8(b""),
            0,
            token_uri,
            signer::address_of(resource_signer),
            1,
            0,
            // This variable sets if we want to allow mutation for token maximum, uri, royalty, description, and properties.
            // Here we enable mutation for properties by setting the last boolean in the vector to true.
            token::create_token_mutability_config(
                &vector<bool>[ false, false, false, false, true ]
            ),
            // We can use property maps to record attributes related to the token.
            // In this example, we are using it to record the receiver's address.
            // We will mutate this field to record the user's address
            // when a user successfully mints a token in the `mint_nft()` function.
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[b""],
            vector<String>[ string::utf8(b"address") ],
        );


        // Retrieve the resource signer's signer capability and store it within the `ModuleData`.
        // Note that by calling `resource_account::retrieve_resource_account_cap` to retrieve the resource account's signer capability,
        // we rotate th resource account's authentication key to 0 and give up our control over the resource account. Before calling this function,
        // the resource account has the same authentication key as the source account so we had control over the resource account.
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);

				// Store the token data id and the resource account's signer capability within the module, so we can programmatically
        // sign for transactions in the `mint_event_ticket()` function.
        move_to(resource_signer, ModuleData {
            signer_cap: resource_signer_cap,
            token_data_id,
            expiration_timestamp: 10000000000,
            minting_enabled: true,
            token_minting_events: account::new_event_handle<TokenMintingEvent>(resource_signer),
        });
    }

    /// Mint an NFT to the receiver.
    public entry fun mint_event_ticket(receiver: &signer) acquires ModuleData {
        let receiver_addr = signer::address_of(receiver);

        // Get the collection minter and check if the collection minting is disabled or expired
        let module_data = borrow_global_mut<ModuleData>(@nft_mint_cost);
        assert!(timestamp::now_seconds() < module_data.expiration_timestamp, error::permission_denied(ECOLLECTION_EXPIRED));
        assert!(module_data.minting_enabled, error::permission_denied(EMINTING_DISABLED));

        // Create a signer of the resource account from the signer capabiity stored in this module.
        let resource_signer = account::create_signer_with_capability(&module_data.signer_cap);

				// Using a resource account and storing its signer capability within the module allows the module to programmatically
        // sign transactions on behalf of the module.
        let token_id = token::mint_token(&resource_signer, module_data.token_data_id, 1);
        token::direct_transfer(&resource_signer, receiver, token_id, 1);

				// Emit event to record the token minting.
        event::emit_event<TokenMintingEvent>(
            &mut module_data.token_minting_events,
            TokenMintingEvent {
                token_receiver_address: receiver_addr,
                token_data_id: module_data.token_data_id,
            }
        );

        // Mutate the token properties to update the property version of this token.
        // Note that here we are re-using the same token data id and only updating the property version.
        // This is because we are simply printing edition of the same token, instead of creating unique
        // tokens. The tokens created this way will have the same token data id, but different property versions.
        let (creator_address, collection, name) = token::get_token_data_id_fields(&module_data.token_data_id);
        token::mutate_token_properties(
            &resource_signer,
            signer::address_of(receiver),
            creator_address,
            collection,
            name,
            0,
            1,
            vector::empty<String>(),
            vector::empty<vector<u8>>(),
            vector::empty<String>(),
        );
    }

    /// Set if minting is enabled for this minting contract
    public entry fun set_minting_enabled(caller: &signer, minting_enabled: bool) acquires ModuleData {
        let caller_address = signer::address_of(caller);
        assert!(caller_address == @admin_addr, error::permission_denied(ENOT_AUTHORIZED));
        let module_data = borrow_global_mut<ModuleData>(@nft_mint_cost);
        module_data.minting_enabled = minting_enabled;
    }

    /// Set the expiration timestamp of this minting contract
    public entry fun set_timestamp(caller: &signer, expiration_timestamp: u64) acquires ModuleData {
        let caller_address = signer::address_of(caller);
        assert!(caller_address == @admin_addr, error::permission_denied(ENOT_AUTHORIZED));
        let module_data = borrow_global_mut<ModuleData>(@nft_mint_cost);
        module_data.expiration_timestamp = expiration_timestamp;
    }

    //
    // Tests
    //

    #[test_only]
    public fun set_up_test(
        origin_account: signer,
        resource_account: &signer,
        collection_token_minter_public_key: &ValidatedPublicKey,
        aptos_framework: signer,
        nft_receiver: &signer,
        timestamp: u64
    ) acquires ModuleData {
        // set up global time for testing purpose
        timestamp::set_time_has_started_for_testing(&aptos_framework);
        timestamp::update_global_time_for_test_secs(timestamp);

        create_account_for_test(signer::address_of(&origin_account));

        // create a resource account from the origin account, mocking the module publishing process
        resource_account::create_resource_account(&origin_account, vector::empty<u8>(), vector::empty<u8>());

        init_module(resource_account);

        let admin = create_account_for_test(@admin_addr);
        let pk_bytes = ed25519::validated_public_key_to_bytes(collection_token_minter_public_key);
        set_public_key(&admin, pk_bytes);

        create_account_for_test(signer::address_of(nft_receiver));
    }

    #[test (origin_account = @0xcafe, resource_account = @0xc3bb8488ab1a5815a9d543d7e41b0e0df46a7396f89b22821f07a4362f75ddc5, nft_receiver = @0x123, aptos_framework = @aptos_framework)]
    public entry fun test_happy_path(origin_account: signer, resource_account: signer, nft_receiver: signer, aptos_framework: signer) acquires ModuleData {
        let (admin_sk, admin_pk) = ed25519::generate_keys();
        set_up_test(origin_account, &resource_account, &admin_pk, aptos_framework, &nft_receiver, 10);

        let receiver_addr = signer::address_of(&nft_receiver);

        // Before: aptos coin balance
        let balance = coin::balance<aptos_coin::AptosCoin>(receiver_addr);
        debug::print(b"Balance BEFORE minting:");
        debug::print(&balance);

        // Mint nft to the receiver
        mint_event_ticket(&nft_receiver);

        // After: aptos coin balance
        let balance = coin::balance<aptos_coin::AptosCoin>(receiver_addr);
        debug::print(b"Balance AFTER minting:");
        debug::print(&balance);

        // check that the nft_receiver has the token in their token store
        // let module_data = borrow_global_mut<ModuleData>(@nft_mint_cost);
        // let resource_signer = account::create_signer_with_capability(&module_data.signer_cap);
        // let resource_signer_addr = signer::address_of(&resource_signer);
        // let token_id = token::create_token_id_raw(resource_signer_addr, string::utf8(b"Collection name"), string::utf8(b"Token name"), 1);
        // let new_token = token::withdraw_token(&nft_receiver, token_id, 1);

        // put the token back since a token isn't droppable
        // token::deposit_token(&nft_receiver, new_token);
    }
}