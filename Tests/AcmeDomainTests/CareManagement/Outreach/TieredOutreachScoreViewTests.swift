@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredOutreachScore("code-443", name: "name-394")
        let view = CareManagement.toTieredOutreachScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredOutreachScoreViews([item, item]).count == 2)
    }
}
