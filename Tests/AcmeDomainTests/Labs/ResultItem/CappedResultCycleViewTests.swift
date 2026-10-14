@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedResultCycle("code-207", label: "label-532")
        let view = Labs.toCappedResultCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedResultCycleViews([item, item]).count == 2)
    }
}
