@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualFloatPoolTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newManualFloatPoolTarget("code-488", name: "name-64")
        let view = Staffing.toManualFloatPoolTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toManualFloatPoolTargetViews([item, item]).count == 2)
    }
}
