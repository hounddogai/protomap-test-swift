@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadMappingStore = Imaging.newMemoryReadMappingStore()
        let item = Imaging.newReadMapping("code-925", name: "name-276")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
