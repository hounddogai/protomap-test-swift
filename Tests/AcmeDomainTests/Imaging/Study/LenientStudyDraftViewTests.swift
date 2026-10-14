@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientStudyDraft("code-961", title: "title-313")
        let view = Imaging.toLenientStudyDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientStudyDraftViews([item, item]).count == 2)
    }
}
