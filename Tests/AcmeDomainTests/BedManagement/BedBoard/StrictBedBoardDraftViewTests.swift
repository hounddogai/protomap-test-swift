@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictBedBoardDraft("code-337", label: "label-812")
        let view = BedManagement.toStrictBedBoardDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictBedBoardDraftViews([item, item]).count == 2)
    }
}
