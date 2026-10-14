@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessWindow("code-33", label: "label-242")
        let view = Consent.toWitnessWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessWindowViews([item, item]).count == 2)
    }
}
