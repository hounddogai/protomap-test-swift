@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptiveReadGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptiveReadGroupStore = Imaging.newMemoryAdaptiveReadGroupStore()
        let item = Imaging.newAdaptiveReadGroup("code-461", name: "name-468")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
