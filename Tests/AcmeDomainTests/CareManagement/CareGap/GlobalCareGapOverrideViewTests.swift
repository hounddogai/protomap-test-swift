@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalCareGapOverride("code-681", name: "name-36")
        let view = CareManagement.toGlobalCareGapOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalCareGapOverrideViews([item, item]).count == 2)
    }
}
