@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultDischargePlanItemViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDefaultDischargePlanItem("code-123", name: "name-216")
        let view = BedManagement.toDefaultDischargePlanItemView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDefaultDischargePlanItemViews([item, item]).count == 2)
    }
}
