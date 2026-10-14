@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedWitnessAdjustment("code-386", label: "label-673")
        let view = Consent.toBatchedWitnessAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedWitnessAdjustmentViews([item, item]).count == 2)
    }
}
