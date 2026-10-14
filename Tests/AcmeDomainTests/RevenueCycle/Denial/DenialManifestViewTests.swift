@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialManifest("code-680", name: "name-175")
        let view = RevenueCycle.toDenialManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialManifestViews([item, item]).count == 2)
    }
}
