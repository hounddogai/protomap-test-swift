@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRemittanceBatch("code-389", name: "name-81")
        let view = RevenueCycle.toRemittanceBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRemittanceBatchViews([item, item]).count == 2)
    }
}
