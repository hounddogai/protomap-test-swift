@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistMappingStore = Imaging.newMemoryWorklistMappingStore()
        let item = Imaging.newWorklistMapping("code-477", name: "name-570")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
