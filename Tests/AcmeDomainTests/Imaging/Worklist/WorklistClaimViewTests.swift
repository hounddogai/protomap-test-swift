@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistClaim("code-618", name: "name-527")
        let view = Imaging.toWorklistClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistClaimViews([item, item]).count == 2)
    }
}
