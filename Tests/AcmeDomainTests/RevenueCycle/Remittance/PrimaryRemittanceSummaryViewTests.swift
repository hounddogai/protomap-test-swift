@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPrimaryRemittanceSummary("code-261", label: "label-113")
        let view = RevenueCycle.toPrimaryRemittanceSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPrimaryRemittanceSummaryViews([item, item]).count == 2)
    }
}
