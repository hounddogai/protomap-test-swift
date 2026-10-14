@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeVariance("code-920", title: "title-76")
        let view = RevenueCycle.toChargeVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeVarianceViews([item, item]).count == 2)
    }
}
