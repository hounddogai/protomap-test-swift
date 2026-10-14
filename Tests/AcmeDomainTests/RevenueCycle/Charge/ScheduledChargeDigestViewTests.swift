@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledChargeDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newScheduledChargeDigest("code-177", name: "name-261")
        let view = RevenueCycle.toScheduledChargeDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toScheduledChargeDigestViews([item, item]).count == 2)
    }
}
