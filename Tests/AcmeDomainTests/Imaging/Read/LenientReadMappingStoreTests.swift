@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientReadMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientReadMappingStore = Imaging.newMemoryLenientReadMappingStore()
        let item = Imaging.newLenientReadMapping("code-845", name: "name-300")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
