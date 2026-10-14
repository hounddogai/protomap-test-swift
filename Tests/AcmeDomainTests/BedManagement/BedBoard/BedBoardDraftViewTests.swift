@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardDraft("code-829", name: "name-159")
        let view = BedManagement.toBedBoardDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardDraftViews([item, item]).count == 2)
    }
}
