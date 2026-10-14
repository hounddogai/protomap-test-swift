@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentReservationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentReservation("code-193", name: "name-195")
        let view = CareManagement.toAssessmentReservationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentReservationViews([item, item]).count == 2)
    }
}
