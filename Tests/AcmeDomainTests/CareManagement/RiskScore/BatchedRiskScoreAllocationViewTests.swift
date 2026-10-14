@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedRiskScoreAllocation("code-958", title: "title-125")
        let view = CareManagement.toBatchedRiskScoreAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedRiskScoreAllocationViews([item, item]).count == 2)
    }
}
