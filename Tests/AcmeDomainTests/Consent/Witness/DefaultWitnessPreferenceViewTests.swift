@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultWitnessPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultWitnessPreference("code-912", name: "name-185")
        let view = Consent.toDefaultWitnessPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultWitnessPreferenceViews([item, item]).count == 2)
    }
}
