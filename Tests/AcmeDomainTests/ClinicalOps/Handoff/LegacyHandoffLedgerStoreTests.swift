@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLegacyHandoffLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LegacyHandoffLedgerStore = ClinicalOps.newMemoryLegacyHandoffLedgerStore()
        let item = ClinicalOps.newLegacyHandoffLedger("code-507", label: "label-692")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
