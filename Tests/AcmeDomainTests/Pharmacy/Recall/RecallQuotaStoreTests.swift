@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallQuotaStore = Pharmacy.newMemoryRecallQuotaStore()
        let item = Pharmacy.newRecallQuota("code-195", title: "title-54")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
