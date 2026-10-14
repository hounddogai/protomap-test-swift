@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRollingDischargePlanTarget("code-21", title: "title-899")
        let view = BedManagement.toRollingDischargePlanTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRollingDischargePlanTargetViews([item, item]).count == 2)
    }
}
