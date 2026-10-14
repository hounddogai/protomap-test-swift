@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveAssessmentAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveAssessmentAssignmentStore = CareManagement.newMemoryAdaptiveAssessmentAssignmentStore()
        let item = CareManagement.newAdaptiveAssessmentAssignment("code-586", title: "title-500")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
