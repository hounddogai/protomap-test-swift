@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardProfile("code-177", name: "name-267")
        let view = BedManagement.toBedBoardProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardProfileViews([item, item]).count == 2)
    }
}
