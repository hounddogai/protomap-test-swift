@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackSpecimenBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackSpecimenBundle("code-336", label: "label-436")
        let view = Labs.toFallbackSpecimenBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackSpecimenBundleViews([item, item]).count == 2)
    }
}
