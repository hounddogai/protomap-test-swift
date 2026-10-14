@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachDigest("code-898", name: "name-826")
        let view = CareManagement.toOutreachDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachDigestViews([item, item]).count == 2)
    }
}
