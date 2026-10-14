@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeAgreement("code-738", title: "title-521")
        let view = Labs.toReferenceRangeAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeAgreementViews([item, item]).count == 2)
    }
}
