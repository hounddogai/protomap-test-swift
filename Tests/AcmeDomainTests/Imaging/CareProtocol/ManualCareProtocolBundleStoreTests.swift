@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualCareProtocolBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualCareProtocolBundleStore = Imaging.newMemoryManualCareProtocolBundleStore()
        let item = Imaging.newManualCareProtocolBundle("code-456", title: "title-530")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
