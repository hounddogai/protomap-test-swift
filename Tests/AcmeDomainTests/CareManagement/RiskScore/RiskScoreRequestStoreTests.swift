@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreRequestStore = CareManagement.newMemoryRiskScoreRequestStore()
        let item = CareManagement.newRiskScoreRequest("code-718", title: "title-911")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
