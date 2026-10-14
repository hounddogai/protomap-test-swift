@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenScore("code-329", name: "name-965")
        let view = Labs.toSpecimenScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenScoreViews([item, item]).count == 2)
    }
}
