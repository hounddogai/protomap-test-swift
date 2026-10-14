@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredClaimGroup("code-612", title: "title-351")
        let view = RevenueCycle.toTieredClaimGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredClaimGroupViews([item, item]).count == 2)
    }
}
