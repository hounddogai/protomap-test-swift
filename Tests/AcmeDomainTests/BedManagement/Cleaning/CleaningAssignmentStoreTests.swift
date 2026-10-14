@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningAssignmentStore = BedManagement.newMemoryCleaningAssignmentStore()
        let item = BedManagement.newCleaningAssignment("code-354", name: "name-404")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
