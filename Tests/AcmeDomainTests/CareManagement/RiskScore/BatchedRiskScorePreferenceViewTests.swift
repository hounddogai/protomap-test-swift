@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScorePreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedRiskScorePreference("code-159", name: "name-163")
        let view = CareManagement.toBatchedRiskScorePreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedRiskScorePreferenceViews([item, item]).count == 2)
    }
}
