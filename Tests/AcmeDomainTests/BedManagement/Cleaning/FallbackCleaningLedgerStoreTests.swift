@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackCleaningLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackCleaningLedgerStore = BedManagement.newMemoryFallbackCleaningLedgerStore()
        let item = BedManagement.newFallbackCleaningLedger("code-499", label: "label-498")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
