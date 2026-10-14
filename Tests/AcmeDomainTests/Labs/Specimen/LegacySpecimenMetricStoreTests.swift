@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacySpecimenMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacySpecimenMetricStore = Labs.newMemoryLegacySpecimenMetricStore()
        let item = Labs.newLegacySpecimenMetric("code-329", name: "name-358")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
