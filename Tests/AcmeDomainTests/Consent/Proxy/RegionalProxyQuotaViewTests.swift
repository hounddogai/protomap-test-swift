@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalProxyQuota("code-364", name: "name-910")
        let view = Consent.toRegionalProxyQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalProxyQuotaViews([item, item]).count == 2)
    }
}
