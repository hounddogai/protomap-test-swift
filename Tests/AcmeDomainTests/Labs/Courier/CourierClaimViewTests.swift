@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierClaim("code-561", name: "name-985")
        let view = Labs.toCourierClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierClaimViews([item, item]).count == 2)
    }
}
