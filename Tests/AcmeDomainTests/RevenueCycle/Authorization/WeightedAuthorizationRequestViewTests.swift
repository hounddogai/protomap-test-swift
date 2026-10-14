@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedAuthorizationRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newWeightedAuthorizationRequest("code-24", title: "title-124")
        let view = RevenueCycle.toWeightedAuthorizationRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toWeightedAuthorizationRequestViews([item, item]).count == 2)
    }
}
