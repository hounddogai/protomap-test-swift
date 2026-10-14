@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierTier("code-747", name: "name-673")
        let view = Labs.toCourierTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierTierViews([item, item]).count == 2)
    }
}
