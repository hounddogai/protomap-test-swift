@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultConsentFormCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultConsentFormCycle("code-713", title: "title-289")
        let view = Consent.toDefaultConsentFormCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultConsentFormCycleViews([item, item]).count == 2)
    }
}
