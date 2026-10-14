@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualRemittanceRecord("code-985", name: "name-410")
        let view = RevenueCycle.toManualRemittanceRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualRemittanceRecordViews([item, item]).count == 2)
    }
}
