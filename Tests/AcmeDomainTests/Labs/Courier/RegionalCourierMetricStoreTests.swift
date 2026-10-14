@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalCourierMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalCourierMetricStore = Labs.newMemoryRegionalCourierMetricStore()
        let item = Labs.newRegionalCourierMetric("code-953", label: "label-796")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
