@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingRecallQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingRecallQuotaStore = Pharmacy.newMemoryPendingRecallQuotaStore()
        let item = Pharmacy.newPendingRecallQuota("code-528", name: "name-93")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
