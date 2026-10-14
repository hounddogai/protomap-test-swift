@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingWorklistMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingWorklistMetricStore = Imaging.newMemoryPendingWorklistMetricStore()
        let item = Imaging.newPendingWorklistMetric("code-367", label: "label-202")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
