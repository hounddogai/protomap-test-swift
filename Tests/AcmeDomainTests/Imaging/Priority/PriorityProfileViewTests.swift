@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityProfile("code-473", title: "title-847")
        let view = Imaging.toPriorityProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityProfileViews([item, item]).count == 2)
    }
}
