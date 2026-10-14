@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardRule("code-273", name: "name-61")
        let view = BedManagement.toBedBoardRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardRuleViews([item, item]).count == 2)
    }
}
