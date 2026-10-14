@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedAssessmentBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newWeightedAssessmentBudget("code-888", title: "title-761")
        let view = CareManagement.toWeightedAssessmentBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toWeightedAssessmentBudgetViews([item, item]).count == 2)
    }
}
