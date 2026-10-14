@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessThreshold("code-324", title: "title-216")
        let view = Consent.toWitnessThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessThresholdViews([item, item]).count == 2)
    }
}
