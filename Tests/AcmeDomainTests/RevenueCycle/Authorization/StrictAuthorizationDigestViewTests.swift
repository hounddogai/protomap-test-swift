@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStrictAuthorizationDigest("code-365", name: "name-956")
        let view = RevenueCycle.toStrictAuthorizationDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStrictAuthorizationDigestViews([item, item]).count == 2)
    }
}
