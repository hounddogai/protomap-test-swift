@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryManualSpecimenSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ManualSpecimenSegmentStore = Labs.newMemoryManualSpecimenSegmentStore()
        let item = Labs.newManualSpecimenSegment("code-657", title: "title-927")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
