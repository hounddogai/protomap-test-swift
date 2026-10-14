@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalFloatPoolSummary("code-178", title: "title-521")
        let view = Staffing.toRegionalFloatPoolSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalFloatPoolSummaryViews([item, item]).count == 2)
    }
}
