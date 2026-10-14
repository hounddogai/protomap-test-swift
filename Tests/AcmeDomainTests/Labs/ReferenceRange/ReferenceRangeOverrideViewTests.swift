@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeOverride("code-718", label: "label-339")
        let view = Labs.toReferenceRangeOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeOverrideViews([item, item]).count == 2)
    }
}
