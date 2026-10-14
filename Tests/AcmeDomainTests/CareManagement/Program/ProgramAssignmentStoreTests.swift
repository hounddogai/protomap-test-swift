@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramAssignmentStore = CareManagement.newMemoryProgramAssignmentStore()
        let item = CareManagement.newProgramAssignment("code-526", title: "title-514")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
