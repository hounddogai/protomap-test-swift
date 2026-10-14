@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalResultOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSeasonalResultOverride("code-354", title: "title-348")
        let view = Labs.toSeasonalResultOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSeasonalResultOverrideViews([item, item]).count == 2)
    }
}
