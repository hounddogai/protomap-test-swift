@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryGlobalReadDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.GlobalReadDigestStore = Imaging.newMemoryGlobalReadDigestStore()
        let item = Imaging.newGlobalReadDigest("code-81", name: "name-154")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
