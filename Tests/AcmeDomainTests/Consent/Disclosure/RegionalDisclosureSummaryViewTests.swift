@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalDisclosureSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalDisclosureSummary("code-821", label: "label-950")
        let view = Consent.toRegionalDisclosureSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalDisclosureSummaryViews([item, item]).count == 2)
    }
}
