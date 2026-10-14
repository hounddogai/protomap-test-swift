@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallTierStore = Pharmacy.newMemoryRecallTierStore()
        let item = Pharmacy.newRecallTier("code-726", label: "label-445")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
