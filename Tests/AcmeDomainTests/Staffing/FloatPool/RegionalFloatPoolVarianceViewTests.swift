@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalFloatPoolVariance("code-444", title: "title-9")
        let view = Staffing.toRegionalFloatPoolVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalFloatPoolVarianceViews([item, item]).count == 2)
    }
}
