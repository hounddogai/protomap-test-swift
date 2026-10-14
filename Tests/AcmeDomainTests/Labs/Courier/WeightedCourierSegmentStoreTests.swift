@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedCourierSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedCourierSegmentStore = Labs.newMemoryWeightedCourierSegmentStore()
        let item = Labs.newWeightedCourierSegment("code-212", label: "label-800")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
