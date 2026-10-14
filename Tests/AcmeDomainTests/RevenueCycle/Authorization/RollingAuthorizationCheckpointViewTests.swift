@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingAuthorizationCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingAuthorizationCheckpoint("code-515", name: "name-873")
        let view = RevenueCycle.toRollingAuthorizationCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingAuthorizationCheckpointViews([item, item]).count == 2)
    }
}
