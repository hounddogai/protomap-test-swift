@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeBatch("code-432", name: "name-223")
        let view = RevenueCycle.toChargeBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeBatchViews([item, item]).count == 2)
    }
}
