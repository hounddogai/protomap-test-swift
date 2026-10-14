@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionMetricStore = Pharmacy.newMemoryInteractionMetricStore()
        let item = Pharmacy.newInteractionMetric("code-673", name: "name-552")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
