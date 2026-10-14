@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedReferenceRangeMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newBatchedReferenceRangeMapping("code-297", name: "name-848")
        let view = Labs.toBatchedReferenceRangeMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toBatchedReferenceRangeMappingViews([item, item]).count == 2)
    }
}
