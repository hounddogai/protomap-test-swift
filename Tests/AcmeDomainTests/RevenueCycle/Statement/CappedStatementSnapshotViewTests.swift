@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newCappedStatementSnapshot("code-247", title: "title-878")
        let view = RevenueCycle.toCappedStatementSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toCappedStatementSnapshotViews([item, item]).count == 2)
    }
}
