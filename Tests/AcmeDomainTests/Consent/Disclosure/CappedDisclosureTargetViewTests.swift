@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedDisclosureTarget("code-900", title: "title-109")
        let view = Consent.toCappedDisclosureTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedDisclosureTargetViews([item, item]).count == 2)
    }
}
