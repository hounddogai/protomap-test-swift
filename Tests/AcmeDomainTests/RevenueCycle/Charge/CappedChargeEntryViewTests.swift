@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedChargeEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newCappedChargeEntry("code-244", title: "title-972")
        let view = RevenueCycle.toCappedChargeEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toCappedChargeEntryViews([item, item]).count == 2)
    }
}
