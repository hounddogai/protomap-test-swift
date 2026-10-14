@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalWitnessOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newGlobalWitnessOverride("code-120", label: "label-457")
        let view = Consent.toGlobalWitnessOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toGlobalWitnessOverrideViews([item, item]).count == 2)
    }
}
