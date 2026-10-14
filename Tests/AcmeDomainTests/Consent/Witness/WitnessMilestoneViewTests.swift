@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessMilestone("code-467", title: "title-526")
        let view = Consent.toWitnessMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessMilestoneViews([item, item]).count == 2)
    }
}
