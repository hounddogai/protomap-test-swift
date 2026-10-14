@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferRule("code-191", label: "label-752")
        let view = BedManagement.toTransferRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferRuleViews([item, item]).count == 2)
    }
}
