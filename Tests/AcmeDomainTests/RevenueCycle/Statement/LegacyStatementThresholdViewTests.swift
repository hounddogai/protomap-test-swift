@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLegacyStatementThreshold("code-256", label: "label-846")
        let view = RevenueCycle.toLegacyStatementThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLegacyStatementThresholdViews([item, item]).count == 2)
    }
}
