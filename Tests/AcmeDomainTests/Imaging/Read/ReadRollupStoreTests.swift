@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadRollupStore = Imaging.newMemoryReadRollupStore()
        let item = Imaging.newReadRollup("code-15", title: "title-196")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
