@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveOvertimeAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveOvertimeAgreement("code-37", label: "label-542")
        let view = Staffing.toAdaptiveOvertimeAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveOvertimeAgreementViews([item, item]).count == 2)
    }
}
