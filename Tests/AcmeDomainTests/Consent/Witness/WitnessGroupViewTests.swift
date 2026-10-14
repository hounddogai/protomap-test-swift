@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessGroup("code-874", label: "label-447")
        let view = Consent.toWitnessGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessGroupViews([item, item]).count == 2)
    }
}
