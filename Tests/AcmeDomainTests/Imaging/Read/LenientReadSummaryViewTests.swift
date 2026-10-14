@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientReadSummary("code-186", label: "label-614")
        let view = Imaging.toLenientReadSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientReadSummaryViews([item, item]).count == 2)
    }
}
