@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacySpecimenProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacySpecimenProfile("code-51", label: "label-688")
        let view = Labs.toLegacySpecimenProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacySpecimenProfileViews([item, item]).count == 2)
    }
}
