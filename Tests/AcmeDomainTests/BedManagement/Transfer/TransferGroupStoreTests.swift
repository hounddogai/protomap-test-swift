@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferGroupStore = BedManagement.newMemoryTransferGroupStore()
        let item = BedManagement.newTransferGroup("code-703", name: "name-207")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
