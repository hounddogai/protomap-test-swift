@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyScore("code-347", title: "title-386")
        let view = Imaging.toStudyScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyScoreViews([item, item]).count == 2)
    }
}
