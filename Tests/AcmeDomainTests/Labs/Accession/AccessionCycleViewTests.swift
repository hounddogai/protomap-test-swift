@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionCycle("code-602", label: "label-850")
        let view = Labs.toAccessionCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionCycleViews([item, item]).count == 2)
    }
}
