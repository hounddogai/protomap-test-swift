@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalFloatPoolTarget("code-262", name: "name-359")
        let view = Staffing.toGlobalFloatPoolTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalFloatPoolTargetViews([item, item]).count == 2)
    }
}
