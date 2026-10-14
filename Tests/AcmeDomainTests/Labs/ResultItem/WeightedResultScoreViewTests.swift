@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedResultScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedResultScore("code-892", name: "name-189")
        let view = Labs.toWeightedResultScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedResultScoreViews([item, item]).count == 2)
    }
}
