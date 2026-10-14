@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedReferenceRangeEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedReferenceRangeEstimate("code-845", name: "name-27")
        let view = Labs.toWeightedReferenceRangeEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedReferenceRangeEstimateViews([item, item]).count == 2)
    }
}
