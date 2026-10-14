@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimManifest("code-509", name: "name-571")
        let view = RevenueCycle.toClaimManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimManifestViews([item, item]).count == 2)
    }
}
