@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeCycle("code-153", label: "label-779")
        let view = Labs.toReferenceRangeCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeCycleViews([item, item]).count == 2)
    }
}
