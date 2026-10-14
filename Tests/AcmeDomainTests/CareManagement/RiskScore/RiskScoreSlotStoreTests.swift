@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreSlotStore = CareManagement.newMemoryRiskScoreSlotStore()
        let item = CareManagement.newRiskScoreSlot("code-247", title: "title-234")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
