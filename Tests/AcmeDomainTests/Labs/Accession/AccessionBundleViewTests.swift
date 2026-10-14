@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionBundle("code-502", label: "label-888")
        let view = Labs.toAccessionBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionBundleViews([item, item]).count == 2)
    }
}
