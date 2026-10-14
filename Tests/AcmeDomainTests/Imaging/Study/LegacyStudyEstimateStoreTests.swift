@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLegacyStudyEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LegacyStudyEstimateStore = Imaging.newMemoryLegacyStudyEstimateStore()
        let item = Imaging.newLegacyStudyEstimate("code-628", title: "title-983")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
