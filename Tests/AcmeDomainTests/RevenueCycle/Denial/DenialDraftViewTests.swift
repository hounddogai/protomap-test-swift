@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialDraft("code-179", label: "label-406")
        let view = RevenueCycle.toDenialDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialDraftViews([item, item]).count == 2)
    }
}
