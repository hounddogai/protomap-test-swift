@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDefaultBedBoardBaseline("code-963", name: "name-487")
        let view = BedManagement.toDefaultBedBoardBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDefaultBedBoardBaselineViews([item, item]).count == 2)
    }
}
