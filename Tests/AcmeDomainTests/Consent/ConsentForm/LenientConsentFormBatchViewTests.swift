@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientConsentFormBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLenientConsentFormBatch("code-467", title: "title-249")
        let view = Consent.toLenientConsentFormBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLenientConsentFormBatchViews([item, item]).count == 2)
    }
}
