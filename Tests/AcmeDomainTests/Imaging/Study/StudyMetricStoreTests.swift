@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyMetricStore = Imaging.newMemoryStudyMetricStore()
        let item = Imaging.newStudyMetric("code-324", label: "label-952")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
