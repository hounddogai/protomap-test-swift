@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newDefaultCourierClaim("code-939", name: "name-230")
        let view = Labs.toDefaultCourierClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toDefaultCourierClaimViews([item, item]).count == 2)
    }
}
