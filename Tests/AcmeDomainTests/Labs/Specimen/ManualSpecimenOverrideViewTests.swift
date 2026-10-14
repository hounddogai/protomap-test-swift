@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualSpecimenOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newManualSpecimenOverride("code-118", label: "label-988")
        let view = Labs.toManualSpecimenOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toManualSpecimenOverrideViews([item, item]).count == 2)
    }
}
