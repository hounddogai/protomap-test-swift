@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveRiskScoreCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveRiskScoreCheckpointStore = CareManagement.newMemoryAdaptiveRiskScoreCheckpointStore()
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("code-665", name: "name-891")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
