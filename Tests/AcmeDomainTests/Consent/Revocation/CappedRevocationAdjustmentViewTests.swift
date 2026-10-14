@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedRevocationAdjustment("code-626", label: "label-982")
        let view = Consent.toCappedRevocationAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedRevocationAdjustmentViews([item, item]).count == 2)
    }
}
