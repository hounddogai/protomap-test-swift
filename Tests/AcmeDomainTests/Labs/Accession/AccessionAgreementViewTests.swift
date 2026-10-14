@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionAgreement("code-544", title: "title-125")
        let view = Labs.toAccessionAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionAgreementViews([item, item]).count == 2)
    }
}
