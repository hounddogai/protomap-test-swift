@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedRiskScoreOverride("code-463", label: "label-515")
        let view = CareManagement.toBatchedRiskScoreOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedRiskScoreOverrideViews([item, item]).count == 2)
    }
}
