@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newDefaultCareProtocolAllocation("code-647", title: "title-806")
        let view = Imaging.toDefaultCareProtocolAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toDefaultCareProtocolAllocationViews([item, item]).count == 2)
    }
}
