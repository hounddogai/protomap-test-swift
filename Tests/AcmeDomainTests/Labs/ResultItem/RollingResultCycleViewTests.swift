@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingResultCycle("code-51", title: "title-472")
        let view = Labs.toRollingResultCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingResultCycleViews([item, item]).count == 2)
    }
}
