@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallMetricStore = Pharmacy.newMemoryRecallMetricStore()
        let item = Pharmacy.newRecallMetric("code-389", name: "name-198")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
