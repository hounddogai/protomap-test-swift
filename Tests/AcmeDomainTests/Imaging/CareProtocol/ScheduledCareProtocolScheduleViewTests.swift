@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledCareProtocolSchedule("code-270", name: "name-786")
        let view = Imaging.toScheduledCareProtocolScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledCareProtocolScheduleViews([item, item]).count == 2)
    }
}
