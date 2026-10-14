@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardOverride("code-685", name: "name-319")
        let view = BedManagement.toBedBoardOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardOverrideViews([item, item]).count == 2)
    }
}
