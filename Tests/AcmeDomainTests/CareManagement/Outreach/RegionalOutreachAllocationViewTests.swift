@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRegionalOutreachAllocation("code-467", label: "label-461")
        let view = CareManagement.toRegionalOutreachAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRegionalOutreachAllocationViews([item, item]).count == 2)
    }
}
