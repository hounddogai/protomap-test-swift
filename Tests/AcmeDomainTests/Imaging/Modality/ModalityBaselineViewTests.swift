@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityBaseline("code-408", label: "label-517")
        let view = Imaging.toModalityBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityBaselineViews([item, item]).count == 2)
    }
}
