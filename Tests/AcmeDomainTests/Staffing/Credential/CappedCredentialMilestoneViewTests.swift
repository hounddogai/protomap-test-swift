@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedCredentialMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedCredentialMilestone("code-230", title: "title-128")
        let view = Staffing.toCappedCredentialMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedCredentialMilestoneViews([item, item]).count == 2)
    }
}
