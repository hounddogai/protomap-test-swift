@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLegacyOrderSetEntry("code-28", label: "label-81")
        let view = ClinicalOps.toLegacyOrderSetEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLegacyOrderSetEntryViews([item, item]).count == 2)
    }
}
