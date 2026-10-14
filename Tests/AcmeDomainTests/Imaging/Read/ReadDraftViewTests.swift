@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadDraft("code-355", label: "label-458")
        let view = Imaging.toReadDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadDraftViews([item, item]).count == 2)
    }
}
