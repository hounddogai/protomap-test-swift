@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredRemittanceException("code-129", title: "title-686")
        let view = RevenueCycle.toTieredRemittanceExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredRemittanceExceptionViews([item, item]).count == 2)
    }
}
