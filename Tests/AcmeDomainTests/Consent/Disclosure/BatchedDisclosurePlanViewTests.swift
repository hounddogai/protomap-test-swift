@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosurePlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedDisclosurePlan("code-815", title: "title-629")
        let view = Consent.toBatchedDisclosurePlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedDisclosurePlanViews([item, item]).count == 2)
    }
}
