@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newWeightedClaimGroup("code-679", title: "title-200")
        let view = RevenueCycle.toWeightedClaimGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toWeightedClaimGroupViews([item, item]).count == 2)
    }
}
