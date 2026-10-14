@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageMetric("code-347", name: "name-345")
        let view = Consent.toLanguageMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageMetricViews([item, item]).count == 2)
    }
}
