@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedReadProfile("code-709", name: "name-535")
        let view = Imaging.toWeightedReadProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedReadProfileViews([item, item]).count == 2)
    }
}
