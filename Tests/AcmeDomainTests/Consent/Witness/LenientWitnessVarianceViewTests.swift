@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientWitnessVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLenientWitnessVariance("code-609", name: "name-107")
        let view = Consent.toLenientWitnessVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLenientWitnessVarianceViews([item, item]).count == 2)
    }
}
