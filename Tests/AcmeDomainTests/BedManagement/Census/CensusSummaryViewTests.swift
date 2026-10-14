@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusSummary("code-939", label: "label-21")
        let view = BedManagement.toCensusSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusSummaryViews([item, item]).count == 2)
    }
}
