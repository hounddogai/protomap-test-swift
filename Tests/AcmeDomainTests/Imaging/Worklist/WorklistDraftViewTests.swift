@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistDraft("code-801", name: "name-271")
        let view = Imaging.toWorklistDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistDraftViews([item, item]).count == 2)
    }
}
