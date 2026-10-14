@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryManualCourierMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ManualCourierMetricStore = Labs.newMemoryManualCourierMetricStore()
        let item = Labs.newManualCourierMetric("code-714", title: "title-625")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
