@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newManualOvertimeVariance("code-77", label: "label-542")
        let view = Staffing.toManualOvertimeVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toManualOvertimeVarianceViews([item, item]).count == 2)
    }
}
