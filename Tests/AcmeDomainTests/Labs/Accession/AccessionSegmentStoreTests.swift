@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionSegmentStore = Labs.newMemoryAccessionSegmentStore()
        let item = Labs.newAccessionSegment("code-814", label: "label-15")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
