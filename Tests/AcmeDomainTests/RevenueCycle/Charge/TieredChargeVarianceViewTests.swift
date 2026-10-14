@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredChargeVariance("code-960", title: "title-823")
        let view = RevenueCycle.toTieredChargeVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredChargeVarianceViews([item, item]).count == 2)
    }
}
