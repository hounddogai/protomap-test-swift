@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveRiskScoreThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveRiskScoreThresholdStore = CareManagement.newMemoryAdaptiveRiskScoreThresholdStore()
        let item = CareManagement.newAdaptiveRiskScoreThreshold("code-503", title: "title-274")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
