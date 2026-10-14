@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityRollup("code-981", title: "title-468")
        let view = Imaging.toModalityRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityRollupViews([item, item]).count == 2)
    }
}
