@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolTierStore = Imaging.newMemoryCareProtocolTierStore()
        let item = Imaging.newCareProtocolTier("code-400", title: "title-589")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
