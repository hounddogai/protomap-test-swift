@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientStudyMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientStudyMetricStore = Imaging.newMemoryLenientStudyMetricStore()
        let item = Imaging.newLenientStudyMetric("code-795", label: "label-197")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
