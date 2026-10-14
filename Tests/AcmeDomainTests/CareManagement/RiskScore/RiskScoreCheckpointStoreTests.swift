@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreCheckpointStore = CareManagement.newMemoryRiskScoreCheckpointStore()
        let item = CareManagement.newRiskScoreCheckpoint("code-476", label: "label-633")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
