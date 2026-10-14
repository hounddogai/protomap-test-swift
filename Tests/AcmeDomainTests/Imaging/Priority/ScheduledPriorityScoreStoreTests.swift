@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledPriorityScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledPriorityScoreStore = Imaging.newMemoryScheduledPriorityScoreStore()
        let item = Imaging.newScheduledPriorityScore("code-90", label: "label-405")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
