@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveRevocationTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newAdaptiveRevocationTarget("code-479", title: "title-346")
        let view = Consent.toAdaptiveRevocationTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toAdaptiveRevocationTargetViews([item, item]).count == 2)
    }
}
