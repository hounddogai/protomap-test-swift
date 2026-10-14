@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedCareGapAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedCareGapAssignmentStore = CareManagement.newMemoryBatchedCareGapAssignmentStore()
        let item = CareManagement.newBatchedCareGapAssignment("code-159", title: "title-593")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
