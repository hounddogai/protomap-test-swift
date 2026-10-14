@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionEstimate("code-150", label: "label-847")
        let view = Labs.toAccessionEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionEstimateViews([item, item]).count == 2)
    }
}
