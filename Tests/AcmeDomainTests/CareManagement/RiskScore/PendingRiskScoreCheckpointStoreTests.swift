@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingRiskScoreCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingRiskScoreCheckpointStore = CareManagement.newMemoryPendingRiskScoreCheckpointStore()
        let item = CareManagement.newPendingRiskScoreCheckpoint("code-746", label: "label-376")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
