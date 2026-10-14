@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledDenialBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newScheduledDenialBaseline("code-642", name: "name-81")
        let view = RevenueCycle.toScheduledDenialBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toScheduledDenialBaselineViews([item, item]).count == 2)
    }
}
