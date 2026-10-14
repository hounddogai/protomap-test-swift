@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveDenialVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveDenialVariance("code-915", label: "label-640")
        let view = RevenueCycle.toAdaptiveDenialVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveDenialVarianceViews([item, item]).count == 2)
    }
}
