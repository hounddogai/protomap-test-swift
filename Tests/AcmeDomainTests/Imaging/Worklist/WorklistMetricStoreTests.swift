@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistMetricStore = Imaging.newMemoryWorklistMetricStore()
        let item = Imaging.newWorklistMetric("code-155", name: "name-882")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
