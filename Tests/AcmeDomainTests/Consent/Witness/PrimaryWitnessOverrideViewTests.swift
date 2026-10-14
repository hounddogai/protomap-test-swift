@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryWitnessOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPrimaryWitnessOverride("code-577", title: "title-114")
        let view = Consent.toPrimaryWitnessOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPrimaryWitnessOverrideViews([item, item]).count == 2)
    }
}
