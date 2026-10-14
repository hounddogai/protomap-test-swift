@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimDraft("code-73", title: "title-411")
        let view = RevenueCycle.toClaimDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimDraftViews([item, item]).count == 2)
    }
}
