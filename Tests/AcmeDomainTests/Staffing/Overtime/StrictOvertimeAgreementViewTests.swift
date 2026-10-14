@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictOvertimeAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictOvertimeAgreement("code-814", title: "title-98")
        let view = Staffing.toStrictOvertimeAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictOvertimeAgreementViews([item, item]).count == 2)
    }
}
