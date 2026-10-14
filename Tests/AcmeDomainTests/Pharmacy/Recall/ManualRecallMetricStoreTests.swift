@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualRecallMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualRecallMetricStore = Pharmacy.newMemoryManualRecallMetricStore()
        let item = Pharmacy.newManualRecallMetric("code-719", label: "label-858")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
