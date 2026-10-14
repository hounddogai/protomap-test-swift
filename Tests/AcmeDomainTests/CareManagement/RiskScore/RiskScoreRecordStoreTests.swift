@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreRecordStore = CareManagement.newMemoryRiskScoreRecordStore()
        let item = CareManagement.newRiskScoreRecord("code-464", name: "name-858")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
