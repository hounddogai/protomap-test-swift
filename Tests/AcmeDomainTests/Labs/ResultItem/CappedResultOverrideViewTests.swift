@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedResultOverride("code-288", name: "name-799")
        let view = Labs.toCappedResultOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedResultOverrideViews([item, item]).count == 2)
    }
}
