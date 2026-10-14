@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalRequest("code-67", label: "label-504")
        let view = CareManagement.toGoalRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalRequestViews([item, item]).count == 2)
    }
}
