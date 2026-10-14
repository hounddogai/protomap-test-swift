@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPrimarySpecimenMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PrimarySpecimenMetricStore = Labs.newMemoryPrimarySpecimenMetricStore()
        let item = Labs.newPrimarySpecimenMetric("code-729", label: "label-485")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
