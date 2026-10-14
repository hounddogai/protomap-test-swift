@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptiveSpecimenBundle("code-277", label: "label-879")
        let view = Labs.toAdaptiveSpecimenBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptiveSpecimenBundleViews([item, item]).count == 2)
    }
}
