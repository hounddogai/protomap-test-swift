@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionClaimStore = Pharmacy.newMemoryInteractionClaimStore()
        let item = Pharmacy.newInteractionClaim("code-274", title: "title-915")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
