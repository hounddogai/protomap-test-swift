@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyMapping("code-92", title: "title-752")
        let view = Consent.toProxyMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyMappingViews([item, item]).count == 2)
    }
}
