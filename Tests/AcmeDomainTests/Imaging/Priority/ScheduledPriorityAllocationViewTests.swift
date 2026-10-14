@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledPriorityAllocation("code-802", name: "name-504")
        let view = Imaging.toScheduledPriorityAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledPriorityAllocationViews([item, item]).count == 2)
    }
}
