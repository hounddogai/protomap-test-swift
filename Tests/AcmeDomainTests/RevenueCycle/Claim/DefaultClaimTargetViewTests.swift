@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultClaimTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDefaultClaimTarget("code-204", title: "title-470")
        let view = RevenueCycle.toDefaultClaimTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDefaultClaimTargetViews([item, item]).count == 2)
    }
}
