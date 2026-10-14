@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyEstimate("code-808", label: "label-86")
        let view = Consent.toProxyEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyEstimateViews([item, item]).count == 2)
    }
}
