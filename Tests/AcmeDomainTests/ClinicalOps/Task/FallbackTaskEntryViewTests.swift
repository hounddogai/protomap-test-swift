@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackTaskEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newFallbackTaskEntry("code-555", title: "title-484")
        let view = ClinicalOps.toFallbackTaskEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toFallbackTaskEntryViews([item, item]).count == 2)
    }
}
