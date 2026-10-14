@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistRequest("code-555", label: "label-687")
        let view = Imaging.toWorklistRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistRequestViews([item, item]).count == 2)
    }
}
