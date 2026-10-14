@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionScore("code-46", title: "title-598")
        let view = Labs.toAccessionScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionScoreViews([item, item]).count == 2)
    }
}
