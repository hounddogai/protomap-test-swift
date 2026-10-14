@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialSegment("code-658", label: "label-882")
        let view = Staffing.toCredentialSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialSegmentViews([item, item]).count == 2)
    }
}
