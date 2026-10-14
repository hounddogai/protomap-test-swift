@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalDraft("code-118", label: "label-627")
        let view = CareManagement.toGoalDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalDraftViews([item, item]).count == 2)
    }
}
