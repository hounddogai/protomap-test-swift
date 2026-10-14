@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredHandoffLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredHandoffLedgerStore = ClinicalOps.newMemoryTieredHandoffLedgerStore()
        let item = ClinicalOps.newTieredHandoffLedger("code-43", name: "name-90")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
