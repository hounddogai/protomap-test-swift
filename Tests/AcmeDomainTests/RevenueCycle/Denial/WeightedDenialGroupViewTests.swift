@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedDenialGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newWeightedDenialGroup("code-375", name: "name-345")
        let view = RevenueCycle.toWeightedDenialGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toWeightedDenialGroupViews([item, item]).count == 2)
    }
}
