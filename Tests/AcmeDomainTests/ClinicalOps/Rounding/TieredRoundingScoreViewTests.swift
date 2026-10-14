@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredRoundingScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTieredRoundingScore("code-364", name: "name-778")
        let view = ClinicalOps.toTieredRoundingScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTieredRoundingScoreViews([item, item]).count == 2)
    }
}
