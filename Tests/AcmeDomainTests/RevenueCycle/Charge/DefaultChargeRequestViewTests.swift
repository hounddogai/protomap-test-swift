@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDefaultChargeRequest("code-530", name: "name-484")
        let view = RevenueCycle.toDefaultChargeRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDefaultChargeRequestViews([item, item]).count == 2)
    }
}
