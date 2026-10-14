@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultRevocationMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultRevocationMilestone("code-672", title: "title-340")
        let view = Consent.toDefaultRevocationMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultRevocationMilestoneViews([item, item]).count == 2)
    }
}
