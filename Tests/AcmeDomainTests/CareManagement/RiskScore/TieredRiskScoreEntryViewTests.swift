@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredRiskScoreEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredRiskScoreEntry("code-490", name: "name-618")
        let view = CareManagement.toTieredRiskScoreEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredRiskScoreEntryViews([item, item]).count == 2)
    }
}
