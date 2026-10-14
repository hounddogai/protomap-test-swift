@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedAccessionMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedAccessionMetricStore = Labs.newMemoryCappedAccessionMetricStore()
        let item = Labs.newCappedAccessionMetric("code-101", title: "title-470")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
