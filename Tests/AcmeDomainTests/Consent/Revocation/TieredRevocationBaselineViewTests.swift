@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredRevocationBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newTieredRevocationBaseline("code-972", name: "name-87")
        let view = Consent.toTieredRevocationBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toTieredRevocationBaselineViews([item, item]).count == 2)
    }
}
