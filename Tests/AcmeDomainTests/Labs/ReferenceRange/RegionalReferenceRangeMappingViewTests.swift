@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalReferenceRangeMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRegionalReferenceRangeMapping("code-563", name: "name-374")
        let view = Labs.toRegionalReferenceRangeMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRegionalReferenceRangeMappingViews([item, item]).count == 2)
    }
}
