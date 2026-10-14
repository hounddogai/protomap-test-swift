@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newAdaptiveConsentFormCheckpoint("code-911", title: "title-408")
        let view = Consent.toAdaptiveConsentFormCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toAdaptiveConsentFormCheckpointViews([item, item]).count == 2)
    }
}
