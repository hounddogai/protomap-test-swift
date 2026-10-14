@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolBundleStore = Imaging.newMemoryCareProtocolBundleStore()
        let item = Imaging.newCareProtocolBundle("code-546", name: "name-80")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
