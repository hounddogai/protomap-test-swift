@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingResultThreshold("code-830", name: "name-196")
        let view = Labs.toRollingResultThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingResultThresholdViews([item, item]).count == 2)
    }
}
