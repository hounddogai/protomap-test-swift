@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalRemittanceVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalRemittanceVariance("code-285", name: "name-892")
        let view = RevenueCycle.toRegionalRemittanceVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalRemittanceVarianceViews([item, item]).count == 2)
    }
}
