@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingWorklistSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingWorklistSummaryStore = Imaging.newMemoryPendingWorklistSummaryStore()
        let item = Imaging.newPendingWorklistSummary("code-424", label: "label-188")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
