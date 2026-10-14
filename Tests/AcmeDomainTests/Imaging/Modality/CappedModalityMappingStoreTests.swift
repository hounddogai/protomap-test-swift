@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedModalityMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedModalityMappingStore = Imaging.newMemoryCappedModalityMappingStore()
        let item = Imaging.newCappedModalityMapping("code-833", title: "title-413")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
