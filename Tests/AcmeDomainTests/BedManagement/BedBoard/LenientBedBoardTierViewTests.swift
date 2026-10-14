@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientBedBoardTier("code-332", name: "name-231")
        let view = BedManagement.toLenientBedBoardTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientBedBoardTierViews([item, item]).count == 2)
    }
}
