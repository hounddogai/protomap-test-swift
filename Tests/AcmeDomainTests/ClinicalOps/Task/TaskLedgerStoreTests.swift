@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskLedgerStore = ClinicalOps.newMemoryTaskLedgerStore()
        let item = ClinicalOps.newTaskLedger("code-102", label: "label-155")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
