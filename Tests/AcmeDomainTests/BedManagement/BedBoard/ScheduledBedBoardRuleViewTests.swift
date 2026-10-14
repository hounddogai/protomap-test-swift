@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledBedBoardRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledBedBoardRule("code-366", name: "name-932")
        let view = BedManagement.toScheduledBedBoardRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledBedBoardRuleViews([item, item]).count == 2)
    }
}
