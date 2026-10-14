@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictProxyVariance("code-51", title: "title-297")
        let view = Consent.toStrictProxyVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictProxyVarianceViews([item, item]).count == 2)
    }
}
