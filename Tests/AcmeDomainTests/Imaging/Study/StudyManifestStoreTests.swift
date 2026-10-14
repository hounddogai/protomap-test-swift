@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyManifestStore = Imaging.newMemoryStudyManifestStore()
        let item = Imaging.newStudyManifest("code-420", name: "name-24")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
