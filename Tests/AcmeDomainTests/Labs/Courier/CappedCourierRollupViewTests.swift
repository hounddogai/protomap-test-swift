@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedCourierRollup("code-134", name: "name-511")
        let view = Labs.toCappedCourierRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedCourierRollupViews([item, item]).count == 2)
    }
}
