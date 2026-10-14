@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyMilestone("code-524", name: "name-395")
        let view = Consent.toProxyMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyMilestoneViews([item, item]).count == 2)
    }
}
