@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyWitnessTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLegacyWitnessTier("code-908", title: "title-36")
        let view = Consent.toLegacyWitnessTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLegacyWitnessTierViews([item, item]).count == 2)
    }
}
