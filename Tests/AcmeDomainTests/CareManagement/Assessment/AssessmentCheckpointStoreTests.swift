@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentCheckpointStore = CareManagement.newMemoryAssessmentCheckpointStore()
        let item = CareManagement.newAssessmentCheckpoint("code-233", name: "name-503")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
