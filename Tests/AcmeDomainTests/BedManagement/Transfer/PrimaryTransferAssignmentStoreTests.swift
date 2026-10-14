@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryTransferAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryTransferAssignmentStore = BedManagement.newMemoryPrimaryTransferAssignmentStore()
        let item = BedManagement.newPrimaryTransferAssignment("code-153", name: "name-45")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
