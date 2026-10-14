@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCappedCredentialLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CappedCredentialLedgerStore = Staffing.newMemoryCappedCredentialLedgerStore()
        let item = Staffing.newCappedCredentialLedger("code-364", name: "name-105")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
