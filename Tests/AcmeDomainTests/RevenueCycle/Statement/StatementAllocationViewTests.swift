@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementAllocation("code-423", label: "label-48")
        let view = RevenueCycle.toStatementAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementAllocationViews([item, item]).count == 2)
    }
}
