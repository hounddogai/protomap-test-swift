@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newScheduledCareProtocolDigest("code-963", name: "name-342")
        let view = ClinicalOps.toScheduledCareProtocolDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toScheduledCareProtocolDigestViews([item, item]).count == 2)
    }
}
