@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenRequest("code-169", name: "name-515")
        let view = Labs.toSpecimenRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenRequestViews([item, item]).count == 2)
    }
}
