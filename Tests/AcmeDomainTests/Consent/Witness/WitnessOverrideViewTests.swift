@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessOverride("code-134", title: "title-641")
        let view = Consent.toWitnessOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessOverrideViews([item, item]).count == 2)
    }
}
