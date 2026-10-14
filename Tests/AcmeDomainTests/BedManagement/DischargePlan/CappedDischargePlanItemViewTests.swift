@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedDischargePlanItemViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCappedDischargePlanItem("code-89", name: "name-724")
        let view = BedManagement.toCappedDischargePlanItemView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCappedDischargePlanItemViews([item, item]).count == 2)
    }
}
