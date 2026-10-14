@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newDefaultCareProtocolSchedule("code-656", title: "title-605")
        let view = Imaging.toDefaultCareProtocolScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toDefaultCareProtocolScheduleViews([item, item]).count == 2)
    }
}
