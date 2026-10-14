@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingStatementExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingStatementException("code-543", name: "name-16")
        let view = RevenueCycle.toRollingStatementExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingStatementExceptionViews([item, item]).count == 2)
    }
}
