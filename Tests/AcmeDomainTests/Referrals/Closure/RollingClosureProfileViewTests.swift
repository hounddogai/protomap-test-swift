@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRollingClosureProfile("code-504", title: "title-949")
        let view = Referrals.toRollingClosureProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRollingClosureProfileViews([item, item]).count == 2)
    }
}
