@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedWitnessBundle("code-349", name: "name-818")
        let view = Consent.toBatchedWitnessBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedWitnessBundleViews([item, item]).count == 2)
    }
}
