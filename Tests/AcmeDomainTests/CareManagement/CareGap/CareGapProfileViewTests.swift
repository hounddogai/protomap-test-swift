@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapProfile("code-690", name: "name-619")
        let view = CareManagement.toCareGapProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapProfileViews([item, item]).count == 2)
    }
}
