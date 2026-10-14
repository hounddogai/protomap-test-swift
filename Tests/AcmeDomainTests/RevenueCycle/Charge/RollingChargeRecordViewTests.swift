@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingChargeRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingChargeRecord("code-631", name: "name-803")
        let view = RevenueCycle.toRollingChargeRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingChargeRecordViews([item, item]).count == 2)
    }
}
