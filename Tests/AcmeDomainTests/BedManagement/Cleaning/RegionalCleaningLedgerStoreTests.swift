@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRegionalCleaningLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RegionalCleaningLedgerStore = BedManagement.newMemoryRegionalCleaningLedgerStore()
        let item = BedManagement.newRegionalCleaningLedger("code-523", name: "name-736")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
