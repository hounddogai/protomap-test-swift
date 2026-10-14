@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyAdjustmentStore = Imaging.newMemoryStudyAdjustmentStore()
        let item = Imaging.newStudyAdjustment("code-353", title: "title-402")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
