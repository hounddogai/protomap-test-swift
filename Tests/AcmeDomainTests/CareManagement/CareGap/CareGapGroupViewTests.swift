@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapGroup("code-661", label: "label-75")
        let view = CareManagement.toCareGapGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapGroupViews([item, item]).count == 2)
    }
}
