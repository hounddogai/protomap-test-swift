@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguagePreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguagePreference("code-546", title: "title-350")
        let view = Consent.toLanguagePreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguagePreferenceViews([item, item]).count == 2)
    }
}
