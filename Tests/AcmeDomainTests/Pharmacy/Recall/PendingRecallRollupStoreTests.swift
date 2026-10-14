@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingRecallRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingRecallRollupStore = Pharmacy.newMemoryPendingRecallRollupStore()
        let item = Pharmacy.newPendingRecallRollup("code-812", title: "title-840")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
