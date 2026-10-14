@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageMapping("code-658", label: "label-751")
        let view = Consent.toLanguageMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageMappingViews([item, item]).count == 2)
    }
}
