@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardGroup("code-12", name: "name-372")
        let view = BedManagement.toBedBoardGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardGroupViews([item, item]).count == 2)
    }
}
