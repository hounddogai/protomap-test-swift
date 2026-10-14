@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultScore("code-944", name: "name-985")
        let view = Labs.toResultScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultScoreViews([item, item]).count == 2)
    }
}
