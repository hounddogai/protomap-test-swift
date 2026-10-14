@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientRiskScorePreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientRiskScorePreference("code-880", title: "title-78")
        let view = CareManagement.toLenientRiskScorePreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientRiskScorePreferenceViews([item, item]).count == 2)
    }
}
