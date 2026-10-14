@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessBundle("code-40", label: "label-28")
        let view = Consent.toWitnessBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessBundleViews([item, item]).count == 2)
    }
}
