@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeSlot("code-932", label: "label-509")
        let view = Labs.toReferenceRangeSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeSlotViews([item, item]).count == 2)
    }
}
