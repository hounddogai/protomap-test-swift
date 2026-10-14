@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudySlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudySlotStore = Imaging.newMemoryStudySlotStore()
        let item = Imaging.newStudySlot("code-486", title: "title-49")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
