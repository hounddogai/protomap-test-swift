@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictRevocationBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictRevocationBatch("code-351", label: "label-454")
        let view = Consent.toStrictRevocationBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictRevocationBatchViews([item, item]).count == 2)
    }
}
