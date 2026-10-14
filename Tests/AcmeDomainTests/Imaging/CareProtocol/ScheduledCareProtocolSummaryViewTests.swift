@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledCareProtocolSummary("code-774", label: "label-649")
        let view = Imaging.toScheduledCareProtocolSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledCareProtocolSummaryViews([item, item]).count == 2)
    }
}
