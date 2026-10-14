@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyAccessionThreshold("code-57", label: "label-584")
        let view = Labs.toLegacyAccessionThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyAccessionThresholdViews([item, item]).count == 2)
    }
}
