@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardTier("code-554", title: "title-202")
        let view = BedManagement.toBedBoardTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardTierViews([item, item]).count == 2)
    }
}
