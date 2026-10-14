@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimSummary("code-322", label: "label-7")
        let view = RevenueCycle.toClaimSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimSummaryViews([item, item]).count == 2)
    }
}
