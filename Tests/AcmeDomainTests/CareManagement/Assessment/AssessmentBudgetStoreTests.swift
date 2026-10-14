@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentBudgetStore = CareManagement.newMemoryAssessmentBudgetStore()
        let item = CareManagement.newAssessmentBudget("code-565", label: "label-188")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
