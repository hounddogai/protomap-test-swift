@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardRollup("code-282", label: "label-223")
        let view = BedManagement.toBedBoardRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardRollupViews([item, item]).count == 2)
    }
}
