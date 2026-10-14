@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryFallbackModalityGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.FallbackModalityGroupStore = Imaging.newMemoryFallbackModalityGroupStore()
        let item = Imaging.newFallbackModalityGroup("code-423", title: "title-279")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
