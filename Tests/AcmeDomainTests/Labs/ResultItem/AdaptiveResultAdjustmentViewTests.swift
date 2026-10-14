@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptiveResultAdjustment("code-361", label: "label-189")
        let view = Labs.toAdaptiveResultAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptiveResultAdjustmentViews([item, item]).count == 2)
    }
}
