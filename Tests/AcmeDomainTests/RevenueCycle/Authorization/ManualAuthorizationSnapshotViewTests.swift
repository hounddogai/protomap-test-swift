@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualAuthorizationSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualAuthorizationSnapshot("code-152", title: "title-308")
        let view = RevenueCycle.toManualAuthorizationSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualAuthorizationSnapshotViews([item, item]).count == 2)
    }
}
