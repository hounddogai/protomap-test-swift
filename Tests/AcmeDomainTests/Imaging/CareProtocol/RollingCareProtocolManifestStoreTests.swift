@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRollingCareProtocolManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RollingCareProtocolManifestStore = Imaging.newMemoryRollingCareProtocolManifestStore()
        let item = Imaging.newRollingCareProtocolManifest("code-231", label: "label-723")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
