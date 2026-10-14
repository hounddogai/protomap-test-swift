@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPrimaryRemittanceVariance("code-430", title: "title-576")
        let view = RevenueCycle.toPrimaryRemittanceVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPrimaryRemittanceVarianceViews([item, item]).count == 2)
    }
}
