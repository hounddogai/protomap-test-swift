@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingFormularyMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingFormularyMetricStore = Pharmacy.newMemoryRollingFormularyMetricStore()
        let item = Pharmacy.newRollingFormularyMetric("code-180", title: "title-582")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
