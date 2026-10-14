@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningLedgerStore = BedManagement.newMemoryCleaningLedgerStore()
        let item = BedManagement.newCleaningLedger("code-895", label: "label-898")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
