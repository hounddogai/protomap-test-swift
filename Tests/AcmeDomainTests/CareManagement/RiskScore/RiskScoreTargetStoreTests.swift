@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreTargetStore = CareManagement.newMemoryRiskScoreTargetStore()
        let item = CareManagement.newRiskScoreTarget("code-264", label: "label-507")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
