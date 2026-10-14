@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientResultMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientResultMetricStore = Labs.newMemoryLenientResultMetricStore()
        let item = Labs.newLenientResultMetric("code-132", name: "name-568")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
