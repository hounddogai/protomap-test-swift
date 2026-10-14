@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeAdjustment("code-525", label: "label-381")
        let view = Labs.toReferenceRangeAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeAdjustmentViews([item, item]).count == 2)
    }
}
