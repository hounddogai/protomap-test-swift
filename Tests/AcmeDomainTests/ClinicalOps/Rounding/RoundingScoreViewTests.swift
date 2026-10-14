@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRoundingScore("code-260", label: "label-723")
        let view = ClinicalOps.toRoundingScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRoundingScoreViews([item, item]).count == 2)
    }
}
