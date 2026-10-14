@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledCareProtocolSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledCareProtocolSummaryStore = Imaging.newMemoryScheduledCareProtocolSummaryStore()
        let item = Imaging.newScheduledCareProtocolSummary("code-774", label: "label-649")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
