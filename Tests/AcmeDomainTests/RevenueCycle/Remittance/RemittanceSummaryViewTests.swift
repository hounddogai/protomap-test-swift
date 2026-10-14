@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRemittanceSummary("code-810", label: "label-312")
        let view = RevenueCycle.toRemittanceSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRemittanceSummaryViews([item, item]).count == 2)
    }
}
