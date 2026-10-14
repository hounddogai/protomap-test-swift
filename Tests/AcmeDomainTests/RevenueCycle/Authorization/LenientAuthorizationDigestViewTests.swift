@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientAuthorizationDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLenientAuthorizationDigest("code-437", label: "label-71")
        let view = RevenueCycle.toLenientAuthorizationDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLenientAuthorizationDigestViews([item, item]).count == 2)
    }
}
