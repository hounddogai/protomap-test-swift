@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newScheduledOvertimeReview("code-46", title: "title-254")
        let view = Staffing.toScheduledOvertimeReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toScheduledOvertimeReviewViews([item, item]).count == 2)
    }
}
