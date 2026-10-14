@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newOrderSetScore("code-515", name: "name-456")
        let view = ClinicalOps.toOrderSetScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toOrderSetScoreViews([item, item]).count == 2)
    }
}
