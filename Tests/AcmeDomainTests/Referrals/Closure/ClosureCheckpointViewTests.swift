@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureCheckpoint("code-944", label: "label-237")
        let view = Referrals.toClosureCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureCheckpointViews([item, item]).count == 2)
    }
}
