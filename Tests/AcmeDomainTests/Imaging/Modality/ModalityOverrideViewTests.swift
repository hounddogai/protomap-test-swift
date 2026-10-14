@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityOverride("code-984", name: "name-43")
        let view = Imaging.toModalityOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityOverrideViews([item, item]).count == 2)
    }
}
