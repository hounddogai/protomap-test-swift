@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureAllocation("code-569", label: "label-785")
        let view = Referrals.toClosureAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureAllocationViews([item, item]).count == 2)
    }
}
