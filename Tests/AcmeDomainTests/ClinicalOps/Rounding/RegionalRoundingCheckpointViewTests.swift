@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalRoundingCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRegionalRoundingCheckpoint("code-593", label: "label-475")
        let view = ClinicalOps.toRegionalRoundingCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRegionalRoundingCheckpointViews([item, item]).count == 2)
    }
}
