@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newAdaptiveBedBoardTarget("code-375", title: "title-319")
        let view = BedManagement.toAdaptiveBedBoardTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toAdaptiveBedBoardTargetViews([item, item]).count == 2)
    }
}
