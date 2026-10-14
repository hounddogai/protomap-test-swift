@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultTarget("code-61", name: "name-229")
        let view = Labs.toResultTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultTargetViews([item, item]).count == 2)
    }
}
