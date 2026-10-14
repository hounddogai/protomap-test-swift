@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveClaimTemplate("code-537", name: "name-293")
        let view = RevenueCycle.toAdaptiveClaimTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveClaimTemplateViews([item, item]).count == 2)
    }
}
