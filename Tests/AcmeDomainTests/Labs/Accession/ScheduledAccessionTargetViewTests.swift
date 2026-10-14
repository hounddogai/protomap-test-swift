@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledAccessionTarget("code-30", label: "label-600")
        let view = Labs.toScheduledAccessionTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledAccessionTargetViews([item, item]).count == 2)
    }
}
