@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationRollup("code-466", label: "label-491")
        let view = Consent.toRevocationRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationRollupViews([item, item]).count == 2)
    }
}
