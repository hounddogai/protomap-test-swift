@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAcuityPlanRecord("code-145", label: "label-864")
        let view = Staffing.toAcuityPlanRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAcuityPlanRecordViews([item, item]).count == 2)
    }
}
