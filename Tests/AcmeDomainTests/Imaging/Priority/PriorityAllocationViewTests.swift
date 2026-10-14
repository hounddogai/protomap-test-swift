@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityAllocation("code-299", title: "title-456")
        let view = Imaging.toPriorityAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityAllocationViews([item, item]).count == 2)
    }
}
