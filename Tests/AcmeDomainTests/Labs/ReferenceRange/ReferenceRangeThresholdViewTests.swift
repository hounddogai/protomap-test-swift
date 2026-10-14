@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeThreshold("code-461", name: "name-678")
        let view = Labs.toReferenceRangeThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeThresholdViews([item, item]).count == 2)
    }
}
