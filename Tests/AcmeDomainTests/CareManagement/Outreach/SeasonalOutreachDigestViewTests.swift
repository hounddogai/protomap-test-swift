@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalOutreachDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalOutreachDigest("code-404", name: "name-206")
        let view = CareManagement.toSeasonalOutreachDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalOutreachDigestViews([item, item]).count == 2)
    }
}
