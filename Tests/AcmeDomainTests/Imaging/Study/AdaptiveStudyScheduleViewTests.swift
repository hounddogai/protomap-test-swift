@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveStudyScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptiveStudySchedule("code-283", name: "name-222")
        let view = Imaging.toAdaptiveStudyScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptiveStudyScheduleViews([item, item]).count == 2)
    }
}
