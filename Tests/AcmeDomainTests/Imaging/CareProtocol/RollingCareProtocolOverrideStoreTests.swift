@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRollingCareProtocolOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RollingCareProtocolOverrideStore = Imaging.newMemoryRollingCareProtocolOverrideStore()
        let item = Imaging.newRollingCareProtocolOverride("code-950", title: "title-505")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
