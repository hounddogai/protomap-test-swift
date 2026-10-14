@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPrimaryAccessionClaim("code-884", name: "name-50")
        let view = Labs.toPrimaryAccessionClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPrimaryAccessionClaimViews([item, item]).count == 2)
    }
}
