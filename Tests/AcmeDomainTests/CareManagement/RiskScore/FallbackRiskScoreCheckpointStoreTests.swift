@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryFallbackRiskScoreCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.FallbackRiskScoreCheckpointStore = CareManagement.newMemoryFallbackRiskScoreCheckpointStore()
        let item = CareManagement.newFallbackRiskScoreCheckpoint("code-911", title: "title-523")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
