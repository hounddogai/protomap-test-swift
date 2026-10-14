@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyDigestStore = Imaging.newMemoryStudyDigestStore()
        let item = Imaging.newStudyDigest("code-707", title: "title-742")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
