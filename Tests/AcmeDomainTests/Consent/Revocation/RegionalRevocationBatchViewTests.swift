@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalRevocationBatch("code-83", title: "title-325")
        let view = Consent.toRegionalRevocationBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalRevocationBatchViews([item, item]).count == 2)
    }
}
