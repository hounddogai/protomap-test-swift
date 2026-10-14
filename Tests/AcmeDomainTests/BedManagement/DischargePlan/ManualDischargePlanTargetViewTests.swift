@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualDischargePlanTarget("code-923", label: "label-265")
        let view = BedManagement.toManualDischargePlanTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualDischargePlanTargetViews([item, item]).count == 2)
    }
}
