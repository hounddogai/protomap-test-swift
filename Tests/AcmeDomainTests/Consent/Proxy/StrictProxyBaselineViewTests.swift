@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictProxyBaseline("code-508", title: "title-44")
        let view = Consent.toStrictProxyBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictProxyBaselineViews([item, item]).count == 2)
    }
}
