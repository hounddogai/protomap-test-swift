@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryDischargePlanLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryDischargePlanLedgerStore = BedManagement.newMemoryPrimaryDischargePlanLedgerStore()
        let item = BedManagement.newPrimaryDischargePlanLedger("code-503", title: "title-922")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
