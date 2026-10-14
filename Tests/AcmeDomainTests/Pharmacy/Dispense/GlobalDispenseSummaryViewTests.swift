@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalDispenseSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newGlobalDispenseSummary("code-281", title: "title-721")
        let view = Pharmacy.toGlobalDispenseSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toGlobalDispenseSummaryViews([item, item]).count == 2)
    }
}
