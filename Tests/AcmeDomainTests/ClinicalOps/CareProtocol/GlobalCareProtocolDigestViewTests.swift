@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalCareProtocolDigest("code-270", title: "title-700")
        let view = ClinicalOps.toGlobalCareProtocolDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalCareProtocolDigestViews([item, item]).count == 2)
    }
}
