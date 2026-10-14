@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedGoalTemplate("code-494", name: "name-103")
        let view = CareManagement.toBatchedGoalTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedGoalTemplateViews([item, item]).count == 2)
    }
}
