@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAdaptiveRiskScoreThreshold("code-503", title: "title-274")
        let view = CareManagement.toAdaptiveRiskScoreThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAdaptiveRiskScoreThresholdViews([item, item]).count == 2)
    }
}
