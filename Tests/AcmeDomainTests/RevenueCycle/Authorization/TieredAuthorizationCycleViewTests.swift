@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredAuthorizationCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredAuthorizationCycle("code-794", name: "name-376")
        let view = RevenueCycle.toTieredAuthorizationCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredAuthorizationCycleViews([item, item]).count == 2)
    }
}
