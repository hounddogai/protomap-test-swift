@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedRevocationSummary("code-547", label: "label-78")
        let view = Consent.toCappedRevocationSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedRevocationSummaryViews([item, item]).count == 2)
    }
}
