@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLegacyCredentialSchedule("code-392", label: "label-350")
        let view = Staffing.toLegacyCredentialScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLegacyCredentialScheduleViews([item, item]).count == 2)
    }
}
