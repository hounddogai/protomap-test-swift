@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenCycle("code-471", name: "name-263")
        let view = Labs.toSpecimenCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenCycleViews([item, item]).count == 2)
    }
}
