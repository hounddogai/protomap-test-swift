@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityClaim("code-349", label: "label-827")
        let view = Imaging.toModalityClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityClaimViews([item, item]).count == 2)
    }
}
