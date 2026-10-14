@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageEstimate("code-958", title: "title-184")
        let view = Consent.toLanguageEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageEstimateViews([item, item]).count == 2)
    }
}
