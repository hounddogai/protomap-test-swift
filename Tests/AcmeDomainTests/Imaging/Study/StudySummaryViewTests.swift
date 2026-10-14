@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudySummary("code-949", title: "title-898")
        let view = Imaging.toStudySummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudySummaryViews([item, item]).count == 2)
    }
}
