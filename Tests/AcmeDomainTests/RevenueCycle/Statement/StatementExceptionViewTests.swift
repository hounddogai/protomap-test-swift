@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementException("code-664", label: "label-947")
        let view = RevenueCycle.toStatementExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementExceptionViews([item, item]).count == 2)
    }
}
