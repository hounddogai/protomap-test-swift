@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudySummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredStudySummary("code-829", name: "name-410")
        let view = Imaging.toTieredStudySummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredStudySummaryViews([item, item]).count == 2)
    }
}
