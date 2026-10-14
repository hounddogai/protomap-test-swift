@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveStatementAllocation("code-951", title: "title-380")
        let view = RevenueCycle.toAdaptiveStatementAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveStatementAllocationViews([item, item]).count == 2)
    }
}
