@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalBedBoardDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalBedBoardDraft("code-911", label: "label-755")
        let view = BedManagement.toGlobalBedBoardDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalBedBoardDraftViews([item, item]).count == 2)
    }
}
