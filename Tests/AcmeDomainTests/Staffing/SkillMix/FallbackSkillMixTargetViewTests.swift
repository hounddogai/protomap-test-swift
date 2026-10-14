@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackSkillMixTarget("code-872", title: "title-891")
        let view = Staffing.toFallbackSkillMixTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackSkillMixTargetViews([item, item]).count == 2)
    }
}
