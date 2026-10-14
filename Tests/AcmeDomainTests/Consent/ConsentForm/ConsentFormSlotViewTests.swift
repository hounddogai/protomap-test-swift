@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormSlot("code-199", name: "name-296")
        let view = Consent.toConsentFormSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormSlotViews([item, item]).count == 2)
    }
}
