@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreWindowStore = CareManagement.newMemoryRiskScoreWindowStore()
        let item = CareManagement.newRiskScoreWindow("code-516", title: "title-105")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
