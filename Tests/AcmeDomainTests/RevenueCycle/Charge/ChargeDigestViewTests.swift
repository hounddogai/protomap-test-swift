@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeDigest("code-349", title: "title-805")
        let view = RevenueCycle.toChargeDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeDigestViews([item, item]).count == 2)
    }
}
