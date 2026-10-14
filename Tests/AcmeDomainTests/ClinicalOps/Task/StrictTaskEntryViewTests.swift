@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newStrictTaskEntry("code-252", label: "label-565")
        let view = ClinicalOps.toStrictTaskEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toStrictTaskEntryViews([item, item]).count == 2)
    }
}
