@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredOutreachSegment("code-928", label: "label-186")
        let view = CareManagement.toTieredOutreachSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredOutreachSegmentViews([item, item]).count == 2)
    }
}
