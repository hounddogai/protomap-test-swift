@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveClaimSnapshot("code-432", name: "name-739")
        let view = RevenueCycle.toAdaptiveClaimSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveClaimSnapshotViews([item, item]).count == 2)
    }
}
