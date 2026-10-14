@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosureRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedDisclosureRequest("code-166", title: "title-322")
        let view = Consent.toBatchedDisclosureRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedDisclosureRequestViews([item, item]).count == 2)
    }
}
