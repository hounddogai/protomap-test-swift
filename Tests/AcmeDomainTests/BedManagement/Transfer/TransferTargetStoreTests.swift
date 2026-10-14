@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferTargetStore = BedManagement.newMemoryTransferTargetStore()
        let item = BedManagement.newTransferTarget("code-728", name: "name-853")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
