@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRegionalOutreachSegment("code-898", title: "title-343")
        let view = CareManagement.toRegionalOutreachSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRegionalOutreachSegmentViews([item, item]).count == 2)
    }
}
