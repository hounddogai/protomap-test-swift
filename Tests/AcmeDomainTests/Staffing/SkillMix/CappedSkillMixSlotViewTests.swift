@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedSkillMixSlot("code-910", title: "title-557")
        let view = Staffing.toCappedSkillMixSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedSkillMixSlotViews([item, item]).count == 2)
    }
}
