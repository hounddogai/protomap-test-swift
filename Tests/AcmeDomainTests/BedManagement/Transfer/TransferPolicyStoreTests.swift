@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferPolicyStore = BedManagement.newMemoryTransferPolicyStore()
        let item = BedManagement.newTransferPolicy("code-811", name: "name-370")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
