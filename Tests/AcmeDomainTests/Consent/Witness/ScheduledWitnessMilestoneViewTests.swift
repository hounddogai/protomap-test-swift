@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledWitnessMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledWitnessMilestone("code-874", title: "title-355")
        let view = Consent.toScheduledWitnessMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledWitnessMilestoneViews([item, item]).count == 2)
    }
}
