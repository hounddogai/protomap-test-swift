@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictSkillMixLedger("code-679", name: "name-382")
        let view = Staffing.toStrictSkillMixLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictSkillMixLedgerViews([item, item]).count == 2)
    }
}
