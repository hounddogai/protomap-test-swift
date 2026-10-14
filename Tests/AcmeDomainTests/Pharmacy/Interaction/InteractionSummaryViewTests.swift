@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionSummary("code-856", title: "title-450")
        let view = Pharmacy.toInteractionSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionSummaryViews([item, item]).count == 2)
    }
}
