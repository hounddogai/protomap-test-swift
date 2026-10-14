@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionPolicy("code-102", title: "title-454")
        let view = Labs.toAccessionPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionPolicyViews([item, item]).count == 2)
    }
}
