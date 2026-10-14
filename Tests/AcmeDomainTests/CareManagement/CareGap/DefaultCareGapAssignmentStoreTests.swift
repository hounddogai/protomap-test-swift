@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultCareGapAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultCareGapAssignmentStore = CareManagement.newMemoryDefaultCareGapAssignmentStore()
        let item = CareManagement.newDefaultCareGapAssignment("code-291", name: "name-77")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
