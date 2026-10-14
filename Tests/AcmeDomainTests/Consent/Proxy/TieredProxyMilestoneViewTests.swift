@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredProxyMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newTieredProxyMilestone("code-4", name: "name-289")
        let view = Consent.toTieredProxyMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toTieredProxyMilestoneViews([item, item]).count == 2)
    }
}
