@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalAssessmentCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalAssessmentCheckpointStore = CareManagement.newMemoryGlobalAssessmentCheckpointStore()
        let item = CareManagement.newGlobalAssessmentCheckpoint("code-188", name: "name-577")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
