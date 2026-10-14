@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadOverrideStore = Imaging.newMemoryReadOverrideStore()
        let item = Imaging.newReadOverride("code-977", label: "label-340")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
