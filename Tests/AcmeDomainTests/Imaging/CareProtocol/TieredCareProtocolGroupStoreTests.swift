@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredCareProtocolGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredCareProtocolGroupStore = Imaging.newMemoryTieredCareProtocolGroupStore()
        let item = Imaging.newTieredCareProtocolGroup("code-599", title: "title-472")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
