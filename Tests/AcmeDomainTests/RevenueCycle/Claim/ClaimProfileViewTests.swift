@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimProfile("code-503", name: "name-361")
        let view = RevenueCycle.toClaimProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimProfileViews([item, item]).count == 2)
    }
}
