@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessVariance("code-45", label: "label-757")
        let view = Consent.toWitnessVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessVarianceViews([item, item]).count == 2)
    }
}
