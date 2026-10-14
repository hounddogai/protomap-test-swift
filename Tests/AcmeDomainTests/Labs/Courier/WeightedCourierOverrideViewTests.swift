@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedCourierOverride("code-774", label: "label-786")
        let view = Labs.toWeightedCourierOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedCourierOverrideViews([item, item]).count == 2)
    }
}
