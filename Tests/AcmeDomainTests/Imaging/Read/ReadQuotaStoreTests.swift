@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadQuotaStore = Imaging.newMemoryReadQuotaStore()
        let item = Imaging.newReadQuota("code-686", title: "title-562")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
