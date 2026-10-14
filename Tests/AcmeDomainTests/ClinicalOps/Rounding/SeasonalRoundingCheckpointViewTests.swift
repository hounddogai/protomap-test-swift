@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newSeasonalRoundingCheckpoint("code-254", title: "title-456")
        let view = ClinicalOps.toSeasonalRoundingCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toSeasonalRoundingCheckpointViews([item, item]).count == 2)
    }
}
