@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingChargeSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingChargeSegment("code-808", name: "name-320")
        let view = RevenueCycle.toRollingChargeSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingChargeSegmentViews([item, item]).count == 2)
    }
}
