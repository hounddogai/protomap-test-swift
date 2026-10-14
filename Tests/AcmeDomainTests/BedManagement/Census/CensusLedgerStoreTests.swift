@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusLedgerStore = BedManagement.newMemoryCensusLedgerStore()
        let item = BedManagement.newCensusLedger("code-523", name: "name-22")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
