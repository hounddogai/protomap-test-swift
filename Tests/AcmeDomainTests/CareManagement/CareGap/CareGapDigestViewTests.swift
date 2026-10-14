@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapDigest("code-869", name: "name-848")
        let view = CareManagement.toCareGapDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapDigestViews([item, item]).count == 2)
    }
}
