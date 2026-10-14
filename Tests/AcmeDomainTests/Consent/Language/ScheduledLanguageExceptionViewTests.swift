@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledLanguageExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledLanguageException("code-737", label: "label-117")
        let view = Consent.toScheduledLanguageExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledLanguageExceptionViews([item, item]).count == 2)
    }
}
