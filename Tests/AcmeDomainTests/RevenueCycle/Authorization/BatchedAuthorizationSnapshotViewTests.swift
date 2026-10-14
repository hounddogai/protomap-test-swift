@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("code-442", title: "title-327")
        let view = RevenueCycle.toBatchedAuthorizationSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedAuthorizationSnapshotViews([item, item]).count == 2)
    }
}
