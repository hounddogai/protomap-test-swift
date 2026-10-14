@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionThreshold("code-355", label: "label-855")
        let view = Labs.toAccessionThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionThresholdViews([item, item]).count == 2)
    }
}
