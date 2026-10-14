@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenSegmentStore = Labs.newMemorySpecimenSegmentStore()
        let item = Labs.newSpecimenSegment("code-860", name: "name-318")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
