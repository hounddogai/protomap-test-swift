@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferRuleStore = BedManagement.newMemoryTransferRuleStore()
        let item = BedManagement.newTransferRule("code-191", label: "label-752")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
