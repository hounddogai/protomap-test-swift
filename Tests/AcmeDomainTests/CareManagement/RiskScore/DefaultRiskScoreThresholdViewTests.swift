@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newDefaultRiskScoreThreshold("code-633", title: "title-406")
        let view = CareManagement.toDefaultRiskScoreThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toDefaultRiskScoreThresholdViews([item, item]).count == 2)
    }
}
