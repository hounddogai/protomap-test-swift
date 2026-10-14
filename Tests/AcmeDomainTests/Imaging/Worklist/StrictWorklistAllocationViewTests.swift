@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictWorklistAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStrictWorklistAllocation("code-404", name: "name-175")
        let view = Imaging.toStrictWorklistAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStrictWorklistAllocationViews([item, item]).count == 2)
    }
}
