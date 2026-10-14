@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreGroupStore = CareManagement.newMemoryRiskScoreGroupStore()
        let item = CareManagement.newRiskScoreGroup("code-54", title: "title-274")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
