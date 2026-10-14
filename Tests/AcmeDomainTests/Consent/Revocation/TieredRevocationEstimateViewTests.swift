@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredRevocationEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newTieredRevocationEstimate("code-877", label: "label-612")
        let view = Consent.toTieredRevocationEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toTieredRevocationEstimateViews([item, item]).count == 2)
    }
}
