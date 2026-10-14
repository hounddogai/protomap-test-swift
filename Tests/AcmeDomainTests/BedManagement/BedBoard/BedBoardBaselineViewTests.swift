@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardBaseline("code-964", label: "label-888")
        let view = BedManagement.toBedBoardBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardBaselineViews([item, item]).count == 2)
    }
}
