@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedWorklistRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedWorklistRequest("code-720", title: "title-386")
        let view = Imaging.toWeightedWorklistRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedWorklistRequestViews([item, item]).count == 2)
    }
}
