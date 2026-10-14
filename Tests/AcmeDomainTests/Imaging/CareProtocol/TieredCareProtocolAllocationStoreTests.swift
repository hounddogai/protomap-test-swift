@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredCareProtocolAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredCareProtocolAllocationStore = Imaging.newMemoryTieredCareProtocolAllocationStore()
        let item = Imaging.newTieredCareProtocolAllocation("code-192", title: "title-567")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
