@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedChargeEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedChargeEntry("code-952", label: "label-158")
        let view = RevenueCycle.toBatchedChargeEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedChargeEntryViews([item, item]).count == 2)
    }
}
