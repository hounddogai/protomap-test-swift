@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledCleaningAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledCleaningAssignmentStore = BedManagement.newMemoryScheduledCleaningAssignmentStore()
        let item = BedManagement.newScheduledCleaningAssignment("code-271", name: "name-319")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
