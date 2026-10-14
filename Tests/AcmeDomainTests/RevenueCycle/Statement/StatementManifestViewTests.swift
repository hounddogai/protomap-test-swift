@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementManifest("code-801", label: "label-891")
        let view = RevenueCycle.toStatementManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementManifestViews([item, item]).count == 2)
    }
}
