@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLenientResultAgreement("code-582", title: "title-990")
        let view = Labs.toLenientResultAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLenientResultAgreementViews([item, item]).count == 2)
    }
}
