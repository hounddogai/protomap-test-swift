@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallClaimStore = Pharmacy.newMemoryRecallClaimStore()
        let item = Pharmacy.newRecallClaim("code-55", name: "name-771")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
