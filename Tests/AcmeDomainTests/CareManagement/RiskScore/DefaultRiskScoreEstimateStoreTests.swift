@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultRiskScoreEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultRiskScoreEstimateStore = CareManagement.newMemoryDefaultRiskScoreEstimateStore()
        let item = CareManagement.newDefaultRiskScoreEstimate("code-451", label: "label-18")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
