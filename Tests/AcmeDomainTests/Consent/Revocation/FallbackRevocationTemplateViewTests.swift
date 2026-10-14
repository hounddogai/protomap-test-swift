@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newFallbackRevocationTemplate("code-318", title: "title-434")
        let view = Consent.toFallbackRevocationTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toFallbackRevocationTemplateViews([item, item]).count == 2)
    }
}
