@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newDefaultSpecimenPolicy("code-895", name: "name-164")
        let view = Labs.toDefaultSpecimenPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toDefaultSpecimenPolicyViews([item, item]).count == 2)
    }
}
