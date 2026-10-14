@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingAuthorizationSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingAuthorizationSnapshot("code-181", name: "name-877")
        let view = RevenueCycle.toRollingAuthorizationSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingAuthorizationSnapshotViews([item, item]).count == 2)
    }
}
