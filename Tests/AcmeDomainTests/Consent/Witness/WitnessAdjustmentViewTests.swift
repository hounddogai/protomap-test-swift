@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessAdjustment("code-961", title: "title-51")
        let view = Consent.toWitnessAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessAdjustmentViews([item, item]).count == 2)
    }
}
