@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationEstimate("code-400", label: "label-292")
        let view = Consent.toRevocationEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationEstimateViews([item, item]).count == 2)
    }
}
