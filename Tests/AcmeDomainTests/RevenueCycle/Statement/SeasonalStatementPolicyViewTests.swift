@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalStatementPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newSeasonalStatementPolicy("code-741", name: "name-89")
        let view = RevenueCycle.toSeasonalStatementPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toSeasonalStatementPolicyViews([item, item]).count == 2)
    }
}
