@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveAccessionBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptiveAccessionBundle("code-106", label: "label-395")
        let view = Labs.toAdaptiveAccessionBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptiveAccessionBundleViews([item, item]).count == 2)
    }
}
