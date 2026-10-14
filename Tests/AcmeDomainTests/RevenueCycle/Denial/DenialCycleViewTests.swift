@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialCycle("code-187", name: "name-936")
        let view = RevenueCycle.toDenialCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialCycleViews([item, item]).count == 2)
    }
}
