@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPrimaryOutreachDigest("code-967", title: "title-167")
        let view = CareManagement.toPrimaryOutreachDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPrimaryOutreachDigestViews([item, item]).count == 2)
    }
}
