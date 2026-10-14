@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRollingIsolationAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RollingIsolationAssignmentStore = BedManagement.newMemoryRollingIsolationAssignmentStore()
        let item = BedManagement.newRollingIsolationAssignment("code-337", name: "name-264")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
