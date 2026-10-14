@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedCareGapAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedCareGapAssignmentStore = CareManagement.newMemoryCappedCareGapAssignmentStore()
        let item = CareManagement.newCappedCareGapAssignment("code-217", label: "label-197")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
