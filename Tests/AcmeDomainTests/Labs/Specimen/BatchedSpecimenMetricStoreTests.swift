@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryBatchedSpecimenMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.BatchedSpecimenMetricStore = Labs.newMemoryBatchedSpecimenMetricStore()
        let item = Labs.newBatchedSpecimenMetric("code-176", label: "label-349")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
