@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreBaselineStore = CareManagement.newMemoryRiskScoreBaselineStore()
        let item = CareManagement.newRiskScoreBaseline("code-470", name: "name-856")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
