@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultWitnessBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultWitnessBaseline("code-577", name: "name-896")
        let view = Consent.toDefaultWitnessBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultWitnessBaselineViews([item, item]).count == 2)
    }
}
