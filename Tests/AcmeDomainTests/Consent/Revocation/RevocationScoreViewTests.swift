@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationScore("code-345", label: "label-42")
        let view = Consent.toRevocationScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationScoreViews([item, item]).count == 2)
    }
}
