@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessTarget("code-679", name: "name-715")
        let view = Consent.toWitnessTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessTargetViews([item, item]).count == 2)
    }
}
