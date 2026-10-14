@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyCensusMilestone("code-20", name: "name-874")
        let view = BedManagement.toLegacyCensusMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyCensusMilestoneViews([item, item]).count == 2)
    }
}
