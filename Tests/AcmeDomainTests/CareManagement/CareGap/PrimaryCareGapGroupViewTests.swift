@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryCareGapGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPrimaryCareGapGroup("code-638", label: "label-609")
        let view = CareManagement.toPrimaryCareGapGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPrimaryCareGapGroupViews([item, item]).count == 2)
    }
}
