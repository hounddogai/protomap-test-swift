@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentSummaryStore = CareManagement.newMemoryAssessmentSummaryStore()
        let item = CareManagement.newAssessmentSummary("code-34", label: "label-574")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
