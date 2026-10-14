@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalCareGapAllocation("code-994", title: "title-271")
        let view = CareManagement.toGlobalCareGapAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalCareGapAllocationViews([item, item]).count == 2)
    }
}
