@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRiskScoreBundle("code-872", name: "name-280")
        let view = CareManagement.toRiskScoreBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRiskScoreBundleViews([item, item]).count == 2)
    }
}
