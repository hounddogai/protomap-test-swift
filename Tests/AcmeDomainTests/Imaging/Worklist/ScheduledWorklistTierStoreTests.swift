@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledWorklistTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledWorklistTierStore = Imaging.newMemoryScheduledWorklistTierStore()
        let item = Imaging.newScheduledWorklistTier("code-535", title: "title-908")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
