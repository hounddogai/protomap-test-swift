@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalRemittanceExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newGlobalRemittanceException("code-999", name: "name-750")
        let view = RevenueCycle.toGlobalRemittanceExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toGlobalRemittanceExceptionViews([item, item]).count == 2)
    }
}
