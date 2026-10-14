@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalConsentFormBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newGlobalConsentFormBatch("code-521", name: "name-541")
        let view = Consent.toGlobalConsentFormBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toGlobalConsentFormBatchViews([item, item]).count == 2)
    }
}
