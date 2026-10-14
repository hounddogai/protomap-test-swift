@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newGlobalCourierTier("code-892", title: "title-597")
        let view = Labs.toGlobalCourierTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toGlobalCourierTierViews([item, item]).count == 2)
    }
}
