@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalProxyBaseline("code-640", name: "name-506")
        let view = Consent.toRegionalProxyBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalProxyBaselineViews([item, item]).count == 2)
    }
}
