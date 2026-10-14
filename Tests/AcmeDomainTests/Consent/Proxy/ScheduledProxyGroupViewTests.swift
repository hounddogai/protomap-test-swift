@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledProxyGroup("code-535", label: "label-638")
        let view = Consent.toScheduledProxyGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledProxyGroupViews([item, item]).count == 2)
    }
}
