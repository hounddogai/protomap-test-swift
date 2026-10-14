@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackAccessionThreshold("code-632", name: "name-839")
        let view = Labs.toFallbackAccessionThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackAccessionThresholdViews([item, item]).count == 2)
    }
}
