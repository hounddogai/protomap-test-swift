@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredAcuityPlanEntry("code-609", name: "name-367")
        let view = Staffing.toTieredAcuityPlanEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredAcuityPlanEntryViews([item, item]).count == 2)
    }
}
