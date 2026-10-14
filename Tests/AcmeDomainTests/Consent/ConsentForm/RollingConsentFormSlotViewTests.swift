@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingConsentFormSlot("code-716", label: "label-581")
        let view = Consent.toRollingConsentFormSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingConsentFormSlotViews([item, item]).count == 2)
    }
}
