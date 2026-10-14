@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixAgreement("code-8", title: "title-648")
        let view = Staffing.toSkillMixAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixAgreementViews([item, item]).count == 2)
    }
}
