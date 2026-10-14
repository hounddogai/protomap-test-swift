@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPrimaryLanguageProfile("code-52", title: "title-821")
        let view = Consent.toPrimaryLanguageProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPrimaryLanguageProfileViews([item, item]).count == 2)
    }
}
