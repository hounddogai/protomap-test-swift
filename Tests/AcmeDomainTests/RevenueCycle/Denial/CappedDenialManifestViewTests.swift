@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedDenialManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newCappedDenialManifest("code-750", label: "label-232")
        let view = RevenueCycle.toCappedDenialManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toCappedDenialManifestViews([item, item]).count == 2)
    }
}
