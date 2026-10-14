@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalConsentFormSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newSeasonalConsentFormSlot("code-776", label: "label-825")
        let view = Consent.toSeasonalConsentFormSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toSeasonalConsentFormSlotViews([item, item]).count == 2)
    }
}
