@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessBaseline("code-649", label: "label-886")
        let view = Consent.toWitnessBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessBaselineViews([item, item]).count == 2)
    }
}
