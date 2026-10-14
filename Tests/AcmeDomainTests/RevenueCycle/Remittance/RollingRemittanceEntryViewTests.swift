@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingRemittanceEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingRemittanceEntry("code-227", name: "name-82")
        let view = RevenueCycle.toRollingRemittanceEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingRemittanceEntryViews([item, item]).count == 2)
    }
}
