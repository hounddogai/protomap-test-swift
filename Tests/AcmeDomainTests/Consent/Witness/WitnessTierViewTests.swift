@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessTier("code-85", name: "name-885")
        let view = Consent.toWitnessTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessTierViews([item, item]).count == 2)
    }
}
