@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalReferenceRangeAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRegionalReferenceRangeAudit("code-369", label: "label-748")
        let view = Labs.toRegionalReferenceRangeAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRegionalReferenceRangeAuditViews([item, item]).count == 2)
    }
}
