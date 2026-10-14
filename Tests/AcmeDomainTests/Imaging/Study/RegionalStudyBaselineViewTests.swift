@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRegionalStudyBaseline("code-639", name: "name-657")
        let view = Imaging.toRegionalStudyBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRegionalStudyBaselineViews([item, item]).count == 2)
    }
}
