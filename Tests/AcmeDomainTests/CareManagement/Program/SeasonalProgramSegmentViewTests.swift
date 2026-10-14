@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalProgramSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalProgramSegment("code-568", label: "label-266")
        let view = CareManagement.toSeasonalProgramSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalProgramSegmentViews([item, item]).count == 2)
    }
}
