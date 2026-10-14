@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledCourierTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledCourierTier("code-342", title: "title-274")
        let view = Labs.toScheduledCourierTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledCourierTierViews([item, item]).count == 2)
    }
}
