@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeTier("code-863", name: "name-231")
        let view = RevenueCycle.toChargeTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeTierViews([item, item]).count == 2)
    }
}
