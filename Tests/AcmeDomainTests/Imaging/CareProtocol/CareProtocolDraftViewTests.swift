@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolDraft("code-885", name: "name-754")
        let view = Imaging.toCareProtocolDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolDraftViews([item, item]).count == 2)
    }
}
