@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolAllocation("code-737", name: "name-110")
        let view = Imaging.toCareProtocolAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolAllocationViews([item, item]).count == 2)
    }
}
