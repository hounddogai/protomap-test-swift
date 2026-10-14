@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLegacyStatementVariance("code-873", label: "label-335")
        let view = RevenueCycle.toLegacyStatementVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLegacyStatementVarianceViews([item, item]).count == 2)
    }
}
