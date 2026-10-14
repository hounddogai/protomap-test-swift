@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientCareGapAllocation("code-86", title: "title-467")
        let view = CareManagement.toLenientCareGapAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientCareGapAllocationViews([item, item]).count == 2)
    }
}
