@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedRiskScoreOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedRiskScoreOverrideStore = CareManagement.newMemoryBatchedRiskScoreOverrideStore()
        let item = CareManagement.newBatchedRiskScoreOverride("code-463", label: "label-515")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
