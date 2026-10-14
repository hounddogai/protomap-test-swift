@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryBedBoardLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryBedBoardLedgerStore = BedManagement.newMemoryPrimaryBedBoardLedgerStore()
        let item = BedManagement.newPrimaryBedBoardLedger("code-432", label: "label-715")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
