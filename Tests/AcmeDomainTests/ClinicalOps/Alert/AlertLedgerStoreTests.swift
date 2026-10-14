@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertLedgerStore = ClinicalOps.newMemoryAlertLedgerStore()
        let item = ClinicalOps.newAlertLedger("code-112", name: "name-941")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
