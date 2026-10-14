@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallRollupStore = Pharmacy.newMemoryRecallRollupStore()
        let item = Pharmacy.newRecallRollup("code-326", name: "name-533")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
