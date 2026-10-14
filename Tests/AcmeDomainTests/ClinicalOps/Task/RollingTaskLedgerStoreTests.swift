@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingTaskLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingTaskLedgerStore = ClinicalOps.newMemoryRollingTaskLedgerStore()
        let item = ClinicalOps.newRollingTaskLedger("code-775", title: "title-38")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
