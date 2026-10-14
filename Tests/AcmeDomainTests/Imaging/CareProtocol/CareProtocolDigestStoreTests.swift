@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolDigestStore = Imaging.newMemoryCareProtocolDigestStore()
        let item = Imaging.newCareProtocolDigest("code-524", label: "label-615")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
