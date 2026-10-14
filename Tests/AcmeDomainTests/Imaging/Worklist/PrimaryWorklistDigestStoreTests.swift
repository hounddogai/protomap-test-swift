@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrimaryWorklistDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrimaryWorklistDigestStore = Imaging.newMemoryPrimaryWorklistDigestStore()
        let item = Imaging.newPrimaryWorklistDigest("code-811", title: "title-289")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
