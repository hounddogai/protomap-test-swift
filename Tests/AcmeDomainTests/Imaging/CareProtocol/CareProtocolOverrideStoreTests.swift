@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolOverrideStore = Imaging.newMemoryCareProtocolOverrideStore()
        let item = Imaging.newCareProtocolOverride("code-769", label: "label-191")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
