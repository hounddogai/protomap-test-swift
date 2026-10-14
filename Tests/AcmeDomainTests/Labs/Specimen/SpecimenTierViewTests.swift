@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenTier("code-120", label: "label-501")
        let view = Labs.toSpecimenTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenTierViews([item, item]).count == 2)
    }
}
