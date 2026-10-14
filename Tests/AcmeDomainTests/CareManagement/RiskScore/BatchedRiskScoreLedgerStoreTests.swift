@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedRiskScoreLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedRiskScoreLedgerStore = CareManagement.newMemoryBatchedRiskScoreLedgerStore()
        let item = CareManagement.newBatchedRiskScoreLedger("code-897", label: "label-875")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
