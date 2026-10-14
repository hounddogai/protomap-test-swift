@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledRemittanceMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newScheduledRemittanceMapping("code-715", name: "name-482")
        let view = RevenueCycle.toScheduledRemittanceMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toScheduledRemittanceMappingViews([item, item]).count == 2)
    }
}
