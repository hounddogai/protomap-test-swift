@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageWindow("code-951", label: "label-48")
        let view = Consent.toLanguageWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageWindowViews([item, item]).count == 2)
    }
}
