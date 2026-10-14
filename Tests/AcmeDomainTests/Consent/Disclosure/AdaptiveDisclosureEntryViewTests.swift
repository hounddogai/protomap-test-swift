@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveDisclosureEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newAdaptiveDisclosureEntry("code-284", name: "name-259")
        let view = Consent.toAdaptiveDisclosureEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toAdaptiveDisclosureEntryViews([item, item]).count == 2)
    }
}
