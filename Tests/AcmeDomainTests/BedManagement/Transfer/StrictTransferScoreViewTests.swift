@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictTransferScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictTransferScore("code-604", label: "label-553")
        let view = BedManagement.toStrictTransferScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictTransferScoreViews([item, item]).count == 2)
    }
}
