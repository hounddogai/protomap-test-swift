@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredReadQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredReadQuotaStore = Imaging.newMemoryTieredReadQuotaStore()
        let item = Imaging.newTieredReadQuota("code-874", title: "title-150")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
