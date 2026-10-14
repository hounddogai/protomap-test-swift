@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientCareProtocolBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientCareProtocolBundleStore = Imaging.newMemoryLenientCareProtocolBundleStore()
        let item = Imaging.newLenientCareProtocolBundle("code-275", label: "label-726")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
