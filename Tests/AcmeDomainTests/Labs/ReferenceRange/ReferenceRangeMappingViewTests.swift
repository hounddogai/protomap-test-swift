@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeMapping("code-343", name: "name-158")
        let view = Labs.toReferenceRangeMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeMappingViews([item, item]).count == 2)
    }
}
