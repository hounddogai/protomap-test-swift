@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalPreference("code-711", title: "title-756")
        let view = CareManagement.toGoalPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalPreferenceViews([item, item]).count == 2)
    }
}
