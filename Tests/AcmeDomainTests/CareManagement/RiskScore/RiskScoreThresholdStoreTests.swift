@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreThresholdStore = CareManagement.newMemoryRiskScoreThresholdStore()
        let item = CareManagement.newRiskScoreThreshold("code-878", name: "name-870")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
