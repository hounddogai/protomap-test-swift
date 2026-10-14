@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAdaptiveHandoffLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AdaptiveHandoffLedgerStore = ClinicalOps.newMemoryAdaptiveHandoffLedgerStore()
        let item = ClinicalOps.newAdaptiveHandoffLedger("code-962", title: "title-497")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
