@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimDigest("code-453", label: "label-648")
        let view = RevenueCycle.toClaimDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimDigestViews([item, item]).count == 2)
    }
}
