@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newManualWitnessTier("code-668", title: "title-892")
        let view = Consent.toManualWitnessTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toManualWitnessTierViews([item, item]).count == 2)
    }
}
