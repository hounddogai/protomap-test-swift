@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeAgreement("code-668", title: "title-565")
        let view = Staffing.toOvertimeAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeAgreementViews([item, item]).count == 2)
    }
}
