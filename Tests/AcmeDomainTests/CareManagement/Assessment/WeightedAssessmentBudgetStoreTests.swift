@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedAssessmentBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedAssessmentBudgetStore = CareManagement.newMemoryWeightedAssessmentBudgetStore()
        let item = CareManagement.newWeightedAssessmentBudget("code-888", title: "title-761")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
