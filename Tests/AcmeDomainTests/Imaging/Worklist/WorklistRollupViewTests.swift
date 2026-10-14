@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistRollup("code-384", title: "title-367")
        let view = Imaging.toWorklistRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistRollupViews([item, item]).count == 2)
    }
}
