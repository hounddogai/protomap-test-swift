@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultMetricStore = Labs.newMemoryResultMetricStore()
        let item = Labs.newResultMetric("code-337", name: "name-188")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
