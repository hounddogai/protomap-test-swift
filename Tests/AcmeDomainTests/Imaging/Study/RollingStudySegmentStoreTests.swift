@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRollingStudySegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RollingStudySegmentStore = Imaging.newMemoryRollingStudySegmentStore()
        let item = Imaging.newRollingStudySegment("code-393", name: "name-649")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
