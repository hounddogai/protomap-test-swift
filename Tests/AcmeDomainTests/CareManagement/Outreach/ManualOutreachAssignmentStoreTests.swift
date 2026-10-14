@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualOutreachAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualOutreachAssignmentStore = CareManagement.newMemoryManualOutreachAssignmentStore()
        let item = CareManagement.newManualOutreachAssignment("code-298", label: "label-76")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
