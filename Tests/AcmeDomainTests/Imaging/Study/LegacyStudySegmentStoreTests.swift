@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLegacyStudySegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LegacyStudySegmentStore = Imaging.newMemoryLegacyStudySegmentStore()
        let item = Imaging.newLegacyStudySegment("code-359", label: "label-12")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
