@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPrimaryRemittanceRequest("code-44", title: "title-156")
        let view = RevenueCycle.toPrimaryRemittanceRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPrimaryRemittanceRequestViews([item, item]).count == 2)
    }
}
