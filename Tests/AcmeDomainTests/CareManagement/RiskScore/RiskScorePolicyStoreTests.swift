@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScorePolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScorePolicyStore = CareManagement.newMemoryRiskScorePolicyStore()
        let item = CareManagement.newRiskScorePolicy("code-314", title: "title-5")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
