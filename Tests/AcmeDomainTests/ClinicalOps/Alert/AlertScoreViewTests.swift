@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertScore("code-645", title: "title-988")
        let view = ClinicalOps.toAlertScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertScoreViews([item, item]).count == 2)
    }
}
