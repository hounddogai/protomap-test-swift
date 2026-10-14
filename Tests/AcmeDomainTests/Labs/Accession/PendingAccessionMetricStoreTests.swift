@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingAccessionMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingAccessionMetricStore = Labs.newMemoryPendingAccessionMetricStore()
        let item = Labs.newPendingAccessionMetric("code-149", label: "label-682")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
