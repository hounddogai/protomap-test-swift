@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictWitnessQuota("code-204", title: "title-161")
        let view = Consent.toStrictWitnessQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictWitnessQuotaViews([item, item]).count == 2)
    }
}
