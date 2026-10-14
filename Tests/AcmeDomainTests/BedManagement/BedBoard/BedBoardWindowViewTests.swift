@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardWindow("code-803", title: "title-348")
        let view = BedManagement.toBedBoardWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardWindowViews([item, item]).count == 2)
    }
}
