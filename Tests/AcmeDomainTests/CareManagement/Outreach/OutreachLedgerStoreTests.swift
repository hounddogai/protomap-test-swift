@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachLedgerStore = CareManagement.newMemoryOutreachLedgerStore()
        let item = CareManagement.newOutreachLedger("code-700", label: "label-361")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
