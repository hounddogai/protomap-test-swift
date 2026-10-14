@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageRequest("code-115", title: "title-617")
        let view = Consent.toLanguageRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageRequestViews([item, item]).count == 2)
    }
}
