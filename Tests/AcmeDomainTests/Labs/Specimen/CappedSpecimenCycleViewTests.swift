@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedSpecimenCycle("code-408", title: "title-565")
        let view = Labs.toCappedSpecimenCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedSpecimenCycleViews([item, item]).count == 2)
    }
}
