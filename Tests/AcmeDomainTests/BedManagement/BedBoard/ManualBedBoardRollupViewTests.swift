@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualBedBoardRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualBedBoardRollup("code-406", label: "label-869")
        let view = BedManagement.toManualBedBoardRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualBedBoardRollupViews([item, item]).count == 2)
    }
}
