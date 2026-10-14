@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackChargeExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newFallbackChargeException("code-989", title: "title-943")
        let view = RevenueCycle.toFallbackChargeExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toFallbackChargeExceptionViews([item, item]).count == 2)
    }
}
