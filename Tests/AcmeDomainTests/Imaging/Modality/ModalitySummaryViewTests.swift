@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalitySummary("code-893", label: "label-54")
        let view = Imaging.toModalitySummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalitySummaryViews([item, item]).count == 2)
    }
}
