@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLenientRemittanceManifest("code-266", name: "name-980")
        let view = RevenueCycle.toLenientRemittanceManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLenientRemittanceManifestViews([item, item]).count == 2)
    }
}
