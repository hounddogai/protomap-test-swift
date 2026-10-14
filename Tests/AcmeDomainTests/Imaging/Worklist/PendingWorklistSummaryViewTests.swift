@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPendingWorklistSummary("code-424", label: "label-188")
        let view = Imaging.toPendingWorklistSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPendingWorklistSummaryViews([item, item]).count == 2)
    }
}
