@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryDefaultModalityMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.DefaultModalityMappingStore = Imaging.newMemoryDefaultModalityMappingStore()
        let item = Imaging.newDefaultModalityMapping("code-10", title: "title-677")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
