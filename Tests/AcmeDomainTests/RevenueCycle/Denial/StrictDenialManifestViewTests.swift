@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictDenialManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStrictDenialManifest("code-97", title: "title-173")
        let view = RevenueCycle.toStrictDenialManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStrictDenialManifestViews([item, item]).count == 2)
    }
}
