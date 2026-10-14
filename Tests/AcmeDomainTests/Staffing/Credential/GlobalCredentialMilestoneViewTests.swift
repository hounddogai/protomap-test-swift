@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalCredentialMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalCredentialMilestone("code-137", title: "title-408")
        let view = Staffing.toGlobalCredentialMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalCredentialMilestoneViews([item, item]).count == 2)
    }
}
