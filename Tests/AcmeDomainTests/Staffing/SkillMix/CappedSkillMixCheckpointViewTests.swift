@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedSkillMixCheckpoint("code-930", name: "name-462")
        let view = Staffing.toCappedSkillMixCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedSkillMixCheckpointViews([item, item]).count == 2)
    }
}
