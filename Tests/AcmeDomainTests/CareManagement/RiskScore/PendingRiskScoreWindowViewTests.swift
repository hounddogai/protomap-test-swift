@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingRiskScoreWindow("code-555", label: "label-825")
        let view = CareManagement.toPendingRiskScoreWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingRiskScoreWindowViews([item, item]).count == 2)
    }
}
