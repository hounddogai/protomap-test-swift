@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPendingCredentialLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PendingCredentialLedgerStore = Staffing.newMemoryPendingCredentialLedgerStore()
        let item = Staffing.newPendingCredentialLedger("code-819", name: "name-226")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
