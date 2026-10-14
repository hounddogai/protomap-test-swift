@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrioritySchedule("code-913", label: "label-712")
        let view = Imaging.toPriorityScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityScheduleViews([item, item]).count == 2)
    }
}
