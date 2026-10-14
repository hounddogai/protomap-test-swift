@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachScore("code-829", label: "label-156")
        let view = CareManagement.toOutreachScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachScoreViews([item, item]).count == 2)
    }
}
