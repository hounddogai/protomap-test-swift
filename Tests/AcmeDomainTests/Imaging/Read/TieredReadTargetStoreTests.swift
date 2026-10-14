@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredReadTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredReadTargetStore = Imaging.newMemoryTieredReadTargetStore()
        let item = Imaging.newTieredReadTarget("code-14", title: "title-565")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
