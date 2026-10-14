@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackReferenceRangeVariance("code-399", label: "label-960")
        let view = Labs.toFallbackReferenceRangeVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackReferenceRangeVarianceViews([item, item]).count == 2)
    }
}
