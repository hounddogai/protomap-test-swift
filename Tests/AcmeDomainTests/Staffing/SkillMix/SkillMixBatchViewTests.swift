@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixBatch("code-287", title: "title-996")
        let view = Staffing.toSkillMixBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixBatchViews([item, item]).count == 2)
    }
}
