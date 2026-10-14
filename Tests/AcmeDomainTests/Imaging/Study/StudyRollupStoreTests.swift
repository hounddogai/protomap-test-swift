@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyRollupStore = Imaging.newMemoryStudyRollupStore()
        let item = Imaging.newStudyRollup("code-318", title: "title-457")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
