@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRollingStudyMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RollingStudyMetricStore = Imaging.newMemoryRollingStudyMetricStore()
        let item = Imaging.newRollingStudyMetric("code-779", name: "name-482")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
