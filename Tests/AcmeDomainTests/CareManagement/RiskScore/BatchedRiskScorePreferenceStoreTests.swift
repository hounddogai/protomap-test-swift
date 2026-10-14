@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedRiskScorePreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedRiskScorePreferenceStore = CareManagement.newMemoryBatchedRiskScorePreferenceStore()
        let item = CareManagement.newBatchedRiskScorePreference("code-159", name: "name-163")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
