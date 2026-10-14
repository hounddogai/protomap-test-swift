@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedDenialTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newCappedDenialTarget("code-840", name: "name-43")
        let view = RevenueCycle.toCappedDenialTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toCappedDenialTargetViews([item, item]).count == 2)
    }
}
