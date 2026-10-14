@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramSegment("code-272", name: "name-605")
        let view = CareManagement.toProgramSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramSegmentViews([item, item]).count == 2)
    }
}
