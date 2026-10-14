@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultReadBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newDefaultReadBaseline("code-880", name: "name-788")
        let view = Imaging.toDefaultReadBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toDefaultReadBaselineViews([item, item]).count == 2)
    }
}
