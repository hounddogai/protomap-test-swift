@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalRiskScoreTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalRiskScoreTier("code-451", title: "title-304")
        let view = CareManagement.toGlobalRiskScoreTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalRiskScoreTierViews([item, item]).count == 2)
    }
}
