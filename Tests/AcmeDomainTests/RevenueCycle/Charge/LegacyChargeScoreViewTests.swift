@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyChargeScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLegacyChargeScore("code-93", name: "name-489")
        let view = RevenueCycle.toLegacyChargeScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLegacyChargeScoreViews([item, item]).count == 2)
    }
}
