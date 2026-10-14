@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotWindow("code-406", label: "label-744")
        let view = Referrals.toSlotWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotWindowViews([item, item]).count == 2)
    }
}
