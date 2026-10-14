@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyBatch("code-587", label: "label-626")
        let view = Consent.toProxyBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyBatchViews([item, item]).count == 2)
    }
}
