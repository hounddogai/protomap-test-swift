@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionClaim("code-131", name: "name-296")
        let view = Labs.toAccessionClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionClaimViews([item, item]).count == 2)
    }
}
