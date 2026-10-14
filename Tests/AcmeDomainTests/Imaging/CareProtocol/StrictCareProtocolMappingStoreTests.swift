@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStrictCareProtocolMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StrictCareProtocolMappingStore = Imaging.newMemoryStrictCareProtocolMappingStore()
        let item = Imaging.newStrictCareProtocolMapping("code-564", title: "title-739")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
