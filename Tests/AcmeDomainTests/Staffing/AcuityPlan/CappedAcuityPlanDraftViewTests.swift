@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedAcuityPlanDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedAcuityPlanDraft("code-710", name: "name-805")
        let view = Staffing.toCappedAcuityPlanDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedAcuityPlanDraftViews([item, item]).count == 2)
    }
}
