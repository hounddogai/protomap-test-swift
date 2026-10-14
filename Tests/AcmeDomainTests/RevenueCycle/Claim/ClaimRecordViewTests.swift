@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimRecord("code-593", name: "name-865")
        let view = RevenueCycle.toClaimRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimRecordViews([item, item]).count == 2)
    }
}
