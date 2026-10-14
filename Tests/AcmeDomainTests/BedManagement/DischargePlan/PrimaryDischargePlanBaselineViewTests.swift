@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryDischargePlanBaseline("code-163", title: "title-663")
        let view = BedManagement.toPrimaryDischargePlanBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryDischargePlanBaselineViews([item, item]).count == 2)
    }
}
