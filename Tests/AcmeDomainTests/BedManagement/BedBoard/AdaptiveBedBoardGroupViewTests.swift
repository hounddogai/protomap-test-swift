@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newAdaptiveBedBoardGroup("code-421", title: "title-631")
        let view = BedManagement.toAdaptiveBedBoardGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toAdaptiveBedBoardGroupViews([item, item]).count == 2)
    }
}
