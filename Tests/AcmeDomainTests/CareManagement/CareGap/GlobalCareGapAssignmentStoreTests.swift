@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalCareGapAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalCareGapAssignmentStore = CareManagement.newMemoryGlobalCareGapAssignmentStore()
        let item = CareManagement.newGlobalCareGapAssignment("code-314", name: "name-842")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
