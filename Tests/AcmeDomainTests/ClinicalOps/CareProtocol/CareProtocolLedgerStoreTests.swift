@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolLedgerStore = ClinicalOps.newMemoryCareProtocolLedgerStore()
        let item = ClinicalOps.newCareProtocolLedger("code-374", name: "name-187")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
