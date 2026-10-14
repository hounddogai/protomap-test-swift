@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadClaim("code-197", name: "name-790")
        let view = Imaging.toReadClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadClaimViews([item, item]).count == 2)
    }
}
