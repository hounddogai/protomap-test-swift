@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryProxyBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPrimaryProxyBaseline("code-765", name: "name-38")
        let view = Consent.toPrimaryProxyBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPrimaryProxyBaselineViews([item, item]).count == 2)
    }
}
