@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledRoundingScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newScheduledRoundingScore("code-942", name: "name-886")
        let view = ClinicalOps.toScheduledRoundingScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toScheduledRoundingScoreViews([item, item]).count == 2)
    }
}
