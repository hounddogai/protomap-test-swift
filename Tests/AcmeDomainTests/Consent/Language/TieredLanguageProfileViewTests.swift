@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredLanguageProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newTieredLanguageProfile("code-870", title: "title-753")
        let view = Consent.toTieredLanguageProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toTieredLanguageProfileViews([item, item]).count == 2)
    }
}
