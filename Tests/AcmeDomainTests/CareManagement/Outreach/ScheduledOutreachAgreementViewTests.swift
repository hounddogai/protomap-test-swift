@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledOutreachAgreement("code-479", title: "title-802")
        let view = CareManagement.toScheduledOutreachAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledOutreachAgreementViews([item, item]).count == 2)
    }
}
