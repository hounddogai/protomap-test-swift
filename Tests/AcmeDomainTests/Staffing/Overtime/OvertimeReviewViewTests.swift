@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeReview("code-163", name: "name-780")
        let view = Staffing.toOvertimeReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeReviewViews([item, item]).count == 2)
    }
}
