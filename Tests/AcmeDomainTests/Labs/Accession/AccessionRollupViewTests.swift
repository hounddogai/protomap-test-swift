@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionRollup("code-550", name: "name-838")
        let view = Labs.toAccessionRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionRollupViews([item, item]).count == 2)
    }
}
