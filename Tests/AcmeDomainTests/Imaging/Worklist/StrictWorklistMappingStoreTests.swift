@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStrictWorklistMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StrictWorklistMappingStore = Imaging.newMemoryStrictWorklistMappingStore()
        let item = Imaging.newStrictWorklistMapping("code-149", title: "title-327")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
