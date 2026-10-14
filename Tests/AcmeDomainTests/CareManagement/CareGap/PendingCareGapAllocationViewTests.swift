@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingCareGapAllocation("code-160", title: "title-594")
        let view = CareManagement.toPendingCareGapAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingCareGapAllocationViews([item, item]).count == 2)
    }
}
