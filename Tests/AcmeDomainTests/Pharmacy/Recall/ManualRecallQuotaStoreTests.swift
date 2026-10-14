@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualRecallQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualRecallQuotaStore = Pharmacy.newMemoryManualRecallQuotaStore()
        let item = Pharmacy.newManualRecallQuota("code-839", label: "label-907")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
