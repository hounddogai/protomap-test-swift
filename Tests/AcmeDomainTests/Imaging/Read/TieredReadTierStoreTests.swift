@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredReadTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredReadTierStore = Imaging.newMemoryTieredReadTierStore()
        let item = Imaging.newTieredReadTier("code-557", title: "title-968")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
