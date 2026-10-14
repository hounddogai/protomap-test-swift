@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingWorklistScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingWorklistSchedule("code-487", label: "label-743")
        let view = Imaging.toRollingWorklistScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingWorklistScheduleViews([item, item]).count == 2)
    }
}
