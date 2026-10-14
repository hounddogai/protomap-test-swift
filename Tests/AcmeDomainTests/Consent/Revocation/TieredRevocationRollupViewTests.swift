@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredRevocationRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newTieredRevocationRollup("code-239", label: "label-309")
        let view = Consent.toTieredRevocationRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toTieredRevocationRollupViews([item, item]).count == 2)
    }
}
