@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreEstimateStore = CareManagement.newMemoryRiskScoreEstimateStore()
        let item = CareManagement.newRiskScoreEstimate("code-796", title: "title-330")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
