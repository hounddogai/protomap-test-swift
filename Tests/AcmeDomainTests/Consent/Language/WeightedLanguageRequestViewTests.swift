@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedLanguageRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWeightedLanguageRequest("code-103", title: "title-134")
        let view = Consent.toWeightedLanguageRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWeightedLanguageRequestViews([item, item]).count == 2)
    }
}
