@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLenientTransferAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LenientTransferAllocationStore = BedManagement.newMemoryLenientTransferAllocationStore()
        let item = BedManagement.newLenientTransferAllocation("code-297", label: "label-30")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
