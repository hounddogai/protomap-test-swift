@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapOverride("code-615", title: "title-991")
        let view = CareManagement.toCareGapOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapOverrideViews([item, item]).count == 2)
    }
}
