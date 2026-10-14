@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimBaseline("code-697", label: "label-570")
        let view = RevenueCycle.toClaimBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimBaselineViews([item, item]).count == 2)
    }
}
