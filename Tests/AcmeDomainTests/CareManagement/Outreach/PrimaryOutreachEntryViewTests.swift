@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPrimaryOutreachEntry("code-117", title: "title-219")
        let view = CareManagement.toPrimaryOutreachEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPrimaryOutreachEntryViews([item, item]).count == 2)
    }
}
