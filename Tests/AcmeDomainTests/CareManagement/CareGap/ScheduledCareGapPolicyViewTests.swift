@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledCareGapPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledCareGapPolicy("code-881", name: "name-452")
        let view = CareManagement.toScheduledCareGapPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledCareGapPolicyViews([item, item]).count == 2)
    }
}
