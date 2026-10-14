@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedSpecimenCycle("code-298", name: "name-573")
        let view = Labs.toWeightedSpecimenCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedSpecimenCycleViews([item, item]).count == 2)
    }
}
