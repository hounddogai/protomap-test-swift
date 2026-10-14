@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientChargeTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLenientChargeTier("code-655", label: "label-258")
        let view = RevenueCycle.toLenientChargeTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLenientChargeTierViews([item, item]).count == 2)
    }
}
