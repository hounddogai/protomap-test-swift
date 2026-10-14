@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenProfile("code-737", name: "name-452")
        let view = Labs.toSpecimenProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenProfileViews([item, item]).count == 2)
    }
}
