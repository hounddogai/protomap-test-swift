@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingResultMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingResultMetricStore = Labs.newMemoryPendingResultMetricStore()
        let item = Labs.newPendingResultMetric("code-165", label: "label-670")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
