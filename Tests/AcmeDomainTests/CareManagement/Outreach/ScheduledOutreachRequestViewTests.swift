@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledOutreachRequest("code-472", name: "name-381")
        let view = CareManagement.toScheduledOutreachRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledOutreachRequestViews([item, item]).count == 2)
    }
}
