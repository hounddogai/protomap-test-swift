@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRollingCareGapDigest("code-438", title: "title-974")
        let view = CareManagement.toRollingCareGapDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRollingCareGapDigestViews([item, item]).count == 2)
    }
}
