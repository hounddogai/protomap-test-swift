@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictIsolationMilestone("code-738", name: "name-939")
        let view = BedManagement.toStrictIsolationMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictIsolationMilestoneViews([item, item]).count == 2)
    }
}
