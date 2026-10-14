@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierSummary("code-488", name: "name-613")
        let view = Labs.toCourierSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierSummaryViews([item, item]).count == 2)
    }
}
