@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageOverride("code-624", name: "name-765")
        let view = Consent.toLanguageOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageOverrideViews([item, item]).count == 2)
    }
}
