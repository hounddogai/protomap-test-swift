@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultDisclosureProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultDisclosureProfile("code-725", label: "label-393")
        let view = Consent.toDefaultDisclosureProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultDisclosureProfileViews([item, item]).count == 2)
    }
}
