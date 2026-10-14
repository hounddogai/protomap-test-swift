@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyRecordStore = Imaging.newMemoryStudyRecordStore()
        let item = Imaging.newStudyRecord("code-714", label: "label-32")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
