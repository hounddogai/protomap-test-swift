@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultAgreement("code-493", title: "title-823")
        let view = Labs.toResultAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultAgreementViews([item, item]).count == 2)
    }
}
