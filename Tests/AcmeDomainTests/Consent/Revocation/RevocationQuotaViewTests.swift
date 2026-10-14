@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationQuota("code-429", label: "label-796")
        let view = Consent.toRevocationQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationQuotaViews([item, item]).count == 2)
    }
}
