@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferScore("code-586", label: "label-359")
        let view = BedManagement.toTransferScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferScoreViews([item, item]).count == 2)
    }
}
