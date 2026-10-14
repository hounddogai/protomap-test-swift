@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveStatementSnapshot("code-144", name: "name-289")
        let view = RevenueCycle.toAdaptiveStatementSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveStatementSnapshotViews([item, item]).count == 2)
    }
}
