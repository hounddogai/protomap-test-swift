@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredStudyTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredStudyTierStore = Imaging.newMemoryTieredStudyTierStore()
        let item = Imaging.newTieredStudyTier("code-699", label: "label-46")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
