@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityAllocation("code-828", label: "label-933")
        let view = Imaging.toModalityAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityAllocationViews([item, item]).count == 2)
    }
}
