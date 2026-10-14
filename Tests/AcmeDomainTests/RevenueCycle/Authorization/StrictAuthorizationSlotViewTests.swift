@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStrictAuthorizationSlot("code-733", title: "title-21")
        let view = RevenueCycle.toStrictAuthorizationSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStrictAuthorizationSlotViews([item, item]).count == 2)
    }
}
