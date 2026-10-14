@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDefaultRemittanceOverride("code-180", name: "name-753")
        let view = RevenueCycle.toDefaultRemittanceOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDefaultRemittanceOverrideViews([item, item]).count == 2)
    }
}
