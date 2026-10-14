@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDefaultChargeException("code-244", name: "name-590")
        let view = RevenueCycle.toDefaultChargeExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDefaultChargeExceptionViews([item, item]).count == 2)
    }
}
