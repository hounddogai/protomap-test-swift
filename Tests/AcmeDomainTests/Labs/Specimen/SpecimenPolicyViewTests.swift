@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenPolicy("code-226", title: "title-359")
        let view = Labs.toSpecimenPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenPolicyViews([item, item]).count == 2)
    }
}
