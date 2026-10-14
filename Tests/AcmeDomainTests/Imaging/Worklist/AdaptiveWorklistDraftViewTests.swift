@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptiveWorklistDraft("code-777", name: "name-636")
        let view = Imaging.toAdaptiveWorklistDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptiveWorklistDraftViews([item, item]).count == 2)
    }
}
