@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualStatementDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualStatementDigest("code-507", name: "name-142")
        let view = RevenueCycle.toManualStatementDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualStatementDigestViews([item, item]).count == 2)
    }
}
