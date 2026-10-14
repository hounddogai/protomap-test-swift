@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrimaryStudyDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrimaryStudyDigestStore = Imaging.newMemoryPrimaryStudyDigestStore()
        let item = Imaging.newPrimaryStudyDigest("code-420", name: "name-961")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
