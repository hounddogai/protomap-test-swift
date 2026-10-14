@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualCleaningAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualCleaningAssignmentStore = BedManagement.newMemoryManualCleaningAssignmentStore()
        let item = BedManagement.newManualCleaningAssignment("code-153", title: "title-95")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
