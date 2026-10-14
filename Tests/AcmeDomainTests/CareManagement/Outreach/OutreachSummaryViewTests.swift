@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachSummary("code-703", title: "title-697")
        let view = CareManagement.toOutreachSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachSummaryViews([item, item]).count == 2)
    }
}
