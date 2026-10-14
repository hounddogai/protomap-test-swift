@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedCourierAllocation("code-357", name: "name-259")
        let view = Labs.toWeightedCourierAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedCourierAllocationViews([item, item]).count == 2)
    }
}
