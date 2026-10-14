@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveStatementRollup("code-840", title: "title-383")
        let view = RevenueCycle.toAdaptiveStatementRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveStatementRollupViews([item, item]).count == 2)
    }
}
