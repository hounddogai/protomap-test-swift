@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingPrioritySummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingPrioritySummaryStore = Imaging.newMemoryPendingPrioritySummaryStore()
        let item = Imaging.newPendingPrioritySummary("code-613", name: "name-568")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
