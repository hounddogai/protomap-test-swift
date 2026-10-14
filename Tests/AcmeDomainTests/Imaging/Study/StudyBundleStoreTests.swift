@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyBundleStore = Imaging.newMemoryStudyBundleStore()
        let item = Imaging.newStudyBundle("code-740", label: "label-986")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
