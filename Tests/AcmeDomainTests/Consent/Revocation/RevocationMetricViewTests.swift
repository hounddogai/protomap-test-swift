@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationMetric("code-4", name: "name-587")
        let view = Consent.toRevocationMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationMetricViews([item, item]).count == 2)
    }
}
