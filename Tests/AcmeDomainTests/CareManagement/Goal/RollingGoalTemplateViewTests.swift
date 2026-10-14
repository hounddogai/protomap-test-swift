@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingGoalTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRollingGoalTemplate("code-798", label: "label-668")
        let view = CareManagement.toRollingGoalTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRollingGoalTemplateViews([item, item]).count == 2)
    }
}
