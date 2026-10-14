@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingWitnessWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPendingWitnessWindow("code-516", label: "label-174")
        let view = Consent.toPendingWitnessWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPendingWitnessWindowViews([item, item]).count == 2)
    }
}
