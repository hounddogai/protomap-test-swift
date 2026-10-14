@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalStatementEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newGlobalStatementEstimate("code-110", label: "label-694")
        let view = RevenueCycle.toGlobalStatementEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toGlobalStatementEstimateViews([item, item]).count == 2)
    }
}
