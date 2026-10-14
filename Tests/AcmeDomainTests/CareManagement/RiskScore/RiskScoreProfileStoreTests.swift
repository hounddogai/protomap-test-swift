@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreProfileStore = CareManagement.newMemoryRiskScoreProfileStore()
        let item = CareManagement.newRiskScoreProfile("code-191", name: "name-418")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
