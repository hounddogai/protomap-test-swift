@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveAuthorizationAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("code-423", title: "title-542")
        let view = RevenueCycle.toAdaptiveAuthorizationAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveAuthorizationAuditViews([item, item]).count == 2)
    }
}
