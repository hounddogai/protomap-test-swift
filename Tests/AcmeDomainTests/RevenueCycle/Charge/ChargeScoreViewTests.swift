@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeScore("code-547", title: "title-153")
        let view = RevenueCycle.toChargeScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeScoreViews([item, item]).count == 2)
    }
}
