@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageThreshold("code-629", label: "label-174")
        let view = Consent.toLanguageThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageThresholdViews([item, item]).count == 2)
    }
}
