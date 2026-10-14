@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardLedgerStore = BedManagement.newMemoryBedBoardLedgerStore()
        let item = BedManagement.newBedBoardLedger("code-617", name: "name-303")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
