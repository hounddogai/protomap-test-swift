@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingSpecimenMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingSpecimenMetricStore = Labs.newMemoryPendingSpecimenMetricStore()
        let item = Labs.newPendingSpecimenMetric("code-771", label: "label-856")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
