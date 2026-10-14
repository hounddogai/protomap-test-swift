@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimMapping("code-809", name: "name-188")
        let view = RevenueCycle.toClaimMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimMappingViews([item, item]).count == 2)
    }
}
