@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingReferenceRangeRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingReferenceRangeRollup("code-385", label: "label-981")
        let view = Labs.toRollingReferenceRangeRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingReferenceRangeRollupViews([item, item]).count == 2)
    }
}
