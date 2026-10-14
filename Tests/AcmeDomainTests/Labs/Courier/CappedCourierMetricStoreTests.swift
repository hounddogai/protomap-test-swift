@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedCourierMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedCourierMetricStore = Labs.newMemoryCappedCourierMetricStore()
        let item = Labs.newCappedCourierMetric("code-658", name: "name-302")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
