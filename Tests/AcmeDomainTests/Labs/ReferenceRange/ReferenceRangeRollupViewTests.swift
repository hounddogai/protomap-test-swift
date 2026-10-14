@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeRollup("code-311", label: "label-490")
        let view = Labs.toReferenceRangeRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeRollupViews([item, item]).count == 2)
    }
}
