@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackCourierSegment("code-828", title: "title-294")
        let view = Labs.toFallbackCourierSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackCourierSegmentViews([item, item]).count == 2)
    }
}
