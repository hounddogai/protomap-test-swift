@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredWorklistEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredWorklistEntryStore = Imaging.newMemoryTieredWorklistEntryStore()
        let item = Imaging.newTieredWorklistEntry("code-849", title: "title-70")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
