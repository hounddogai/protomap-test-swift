@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientReferenceRangeMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientReferenceRangeMetricStore = Labs.newMemoryLenientReferenceRangeMetricStore()
        let item = Labs.newLenientReferenceRangeMetric("code-705", title: "title-531")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
