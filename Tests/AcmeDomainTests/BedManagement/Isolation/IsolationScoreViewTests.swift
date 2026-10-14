@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationScore("code-341", title: "title-722")
        let view = BedManagement.toIsolationScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationScoreViews([item, item]).count == 2)
    }
}
