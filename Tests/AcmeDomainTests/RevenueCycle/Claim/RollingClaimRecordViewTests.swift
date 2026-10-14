@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingClaimRecord("code-67", name: "name-97")
        let view = RevenueCycle.toRollingClaimRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingClaimRecordViews([item, item]).count == 2)
    }
}
