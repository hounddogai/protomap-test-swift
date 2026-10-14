@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudySegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudySegmentStore = Imaging.newMemoryStudySegmentStore()
        let item = Imaging.newStudySegment("code-977", name: "name-96")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
