@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityMapping("code-308", name: "name-330")
        let view = Imaging.toPriorityMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityMappingViews([item, item]).count == 2)
    }
}
