@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newManualCareGapAllocation("code-931", title: "title-351")
        let view = CareManagement.toManualCareGapAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toManualCareGapAllocationViews([item, item]).count == 2)
    }
}
