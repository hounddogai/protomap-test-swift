@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationVariance("code-225", label: "label-744")
        let view = Consent.toRevocationVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationVarianceViews([item, item]).count == 2)
    }
}
