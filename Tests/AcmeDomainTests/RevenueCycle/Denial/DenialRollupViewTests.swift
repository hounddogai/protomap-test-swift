@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialRollup("code-646", name: "name-587")
        let view = RevenueCycle.toDenialRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialRollupViews([item, item]).count == 2)
    }
}
