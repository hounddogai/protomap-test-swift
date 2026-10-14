@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguagePlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newFallbackLanguagePlan("code-466", title: "title-232")
        let view = Consent.toFallbackLanguagePlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toFallbackLanguagePlanViews([item, item]).count == 2)
    }
}
