@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseSummary("code-721", title: "title-849")
        let view = Pharmacy.toDispenseSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseSummaryViews([item, item]).count == 2)
    }
}
