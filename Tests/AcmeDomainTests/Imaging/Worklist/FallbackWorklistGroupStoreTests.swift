@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryFallbackWorklistGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.FallbackWorklistGroupStore = Imaging.newMemoryFallbackWorklistGroupStore()
        let item = Imaging.newFallbackWorklistGroup("code-169", name: "name-712")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
