@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptiveResultBundle("code-7", name: "name-525")
        let view = Labs.toAdaptiveResultBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptiveResultBundleViews([item, item]).count == 2)
    }
}
