@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxySummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLenientProxySummary("code-906", name: "name-602")
        let view = Consent.toLenientProxySummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLenientProxySummaryViews([item, item]).count == 2)
    }
}
