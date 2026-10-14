@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapAgreement("code-328", title: "title-878")
        let view = CareManagement.toCareGapAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapAgreementViews([item, item]).count == 2)
    }
}
