@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalRevocationScore("code-553", label: "label-414")
        let view = Consent.toRegionalRevocationScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalRevocationScoreViews([item, item]).count == 2)
    }
}
